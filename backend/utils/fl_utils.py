"""
Federated Learning utilities using Flower framework.
Implements client and server components for privacy-preserving fraud detection.
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
import flwr as fl
from flwr.common import Parameters, FitRes, EvaluateRes, Status, Code
from flwr.server.strategy import FedAvg, FedProx, FedOpt
from typing import Dict, List, Tuple, Optional, Any, Union
import numpy as np
import logging
from collections import OrderedDict
import threading
import time
import os

from .model_utils import build_model, get_device
from .metrics_utils import compute_classification_metrics
from .dp_utils import DPTrainer

logger = logging.getLogger(__name__)

class FraudDetectionClient(fl.client.NumPyClient):
    """
    Flower client for federated fraud detection training.
    Handles local training and evaluation with optional differential privacy.
    """
    
    def __init__(self, client_id: str, X_train: np.ndarray, y_train: np.ndarray,
                 X_val: np.ndarray, y_val: np.ndarray, config: Dict[str, Any]):
        """
        Initialize the federated learning client.
        
        Args:
            client_id: Unique identifier for this client
            X_train: Training features
            y_train: Training labels
            X_val: Validation features
            y_val: Validation labels
            config: Configuration dictionary
        """
        self.client_id = client_id
        self.config = config
        self.device = get_device(config)
        
        # Store data
        self.X_train = X_train
        self.y_train = y_train
        self.X_val = X_val
        self.y_val = y_val
        
        # Create data loaders
        from .data_utils import create_data_loaders
        self.train_loader = create_data_loaders(
            X_train, y_train, 
            batch_size=config['model']['batch_size'],
            shuffle=True
        )
        self.val_loader = create_data_loaders(
            X_val, y_val,
            batch_size=config['model']['batch_size'],
            shuffle=False
        )
        
        # Initialize model
        self.model = build_model(X_train.shape[1], config)
        self.model.to(self.device)
        
        # Initialize optimizer
        self.optimizer = optim.Adam(
            self.model.parameters(),
            lr=config['model']['learning_rate'],
            weight_decay=config['model']['weight_decay']
        )
        
        # Loss function
        self.criterion = nn.BCEWithLogitsLoss()
        
        # Differential privacy trainer (if enabled)
        self.dp_trainer = None
        if config['differential_privacy']['enabled']:
            self.dp_trainer = DPTrainer(
                model=self.model,
                optimizer=self.optimizer,
                criterion=self.criterion,
                config=config['differential_privacy']
            )
        
        # Training history
        self.training_history = []
        
        logger.info(f"Initialized client {client_id} with {len(X_train)} training samples")
    
    def get_parameters(self, config: Dict[str, Any]) -> List[np.ndarray]:
        """
        Get model parameters as numpy arrays.
        
        Args:
            config: Configuration from server
            
        Returns:
            List of model parameters as numpy arrays
        """
        return [param.cpu().detach().numpy() for param in self.model.parameters()]
    
    def set_parameters(self, parameters: List[np.ndarray]) -> None:
        """
        Set model parameters from numpy arrays.
        
        Args:
            parameters: List of model parameters as numpy arrays
        """
        params_dict = zip(self.model.state_dict().keys(), parameters)
        state_dict = OrderedDict({k: torch.tensor(v) for k, v in params_dict})
        self.model.load_state_dict(state_dict, strict=True)
    
    def fit(self, parameters: List[np.ndarray], config: Dict[str, Any]) -> Tuple[List[np.ndarray], int, Dict[str, Any]]:
        """
        Train the model on local data.
        
        Args:
            parameters: Global model parameters
            config: Training configuration from server
            
        Returns:
            Tuple of (updated_parameters, num_examples, metrics)
        """
        # Set global parameters
        self.set_parameters(parameters)
        
        # Extract training configuration
        local_epochs = config.get('local_epochs', self.config['model']['local_epochs'])
        round_num = config.get('round', 0)
        
        logger.info(f"Client {self.client_id} starting training for round {round_num}")
        
        # Train the model
        if self.dp_trainer is not None:
            # Train with differential privacy
            train_metrics = self._train_with_dp(local_epochs)
        else:
            # Standard training
            train_metrics = self._train_standard(local_epochs)
        
        # Get updated parameters
        updated_parameters = self.get_parameters({})
        
        # Prepare metrics for server
        metrics = {
            'client_id': self.client_id,
            'round': round_num,
            'train_loss': train_metrics['loss'],
            'train_accuracy': train_metrics['accuracy'],
            'num_examples': len(self.X_train)
        }
        
        # Add DP metrics if applicable
        if self.dp_trainer is not None:
            metrics.update(train_metrics.get('dp_metrics', {}))
        
        self.training_history.append(metrics)
        
        logger.info(f"Client {self.client_id} completed training: "
                   f"loss={train_metrics['loss']:.4f}, acc={train_metrics['accuracy']:.4f}")
        
        return updated_parameters, len(self.X_train), metrics
    
    def evaluate(self, parameters: List[np.ndarray], config: Dict[str, Any]) -> Tuple[float, int, Dict[str, Any]]:
        """
        Evaluate the model on local validation data.
        
        Args:
            parameters: Global model parameters
            config: Evaluation configuration from server
            
        Returns:
            Tuple of (loss, num_examples, metrics)
        """
        # Set global parameters
        self.set_parameters(parameters)
        
        # Evaluate the model
        eval_metrics = self._evaluate()
        
        logger.info(f"Client {self.client_id} evaluation: "
                   f"loss={eval_metrics['loss']:.4f}, auc={eval_metrics['auc']:.4f}")
        
        return eval_metrics['loss'], len(self.X_val), eval_metrics
    
    def _train_standard(self, local_epochs: int) -> Dict[str, Any]:
        """
        Standard training without differential privacy.
        
        Args:
            local_epochs: Number of local training epochs
            
        Returns:
            Training metrics
        """
        self.model.train()
        total_loss = 0.0
        correct_predictions = 0
        total_samples = 0
        
        for epoch in range(local_epochs):
            epoch_loss = 0.0
            epoch_correct = 0
            epoch_samples = 0
            
            for batch_X, batch_y in self.train_loader:
                batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                
                # Forward pass
                self.optimizer.zero_grad()
                outputs = self.model(batch_X).squeeze()
                loss = self.criterion(outputs, batch_y)
                
                # Backward pass
                loss.backward()
                self.optimizer.step()
                
                # Statistics
                epoch_loss += loss.item()
                predictions = torch.sigmoid(outputs) > 0.5
                epoch_correct += (predictions == batch_y).sum().item()
                epoch_samples += batch_y.size(0)
            
            total_loss += epoch_loss
            correct_predictions += epoch_correct
            total_samples += epoch_samples
        
        avg_loss = total_loss / (local_epochs * len(self.train_loader))
        accuracy = correct_predictions / total_samples
        
        return {
            'loss': avg_loss,
            'accuracy': accuracy
        }
    
    def _train_with_dp(self, local_epochs: int) -> Dict[str, Any]:
        """
        Training with differential privacy.
        
        Args:
            local_epochs: Number of local training epochs
            
        Returns:
            Training metrics including DP metrics
        """
        train_metrics = self.dp_trainer.train(self.train_loader, local_epochs)
        return train_metrics
    
    def _evaluate(self) -> Dict[str, Any]:
        """
        Evaluate the model on validation data.
        
        Returns:
            Evaluation metrics
        """
        self.model.eval()
        total_loss = 0.0
        all_predictions = []
        all_labels = []
        
        with torch.no_grad():
            for batch_X, batch_y in self.val_loader:
                batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                
                outputs = self.model(batch_X).squeeze()
                loss = self.criterion(outputs, batch_y)
                
                total_loss += loss.item()
                
                # Store predictions and labels
                probabilities = torch.sigmoid(outputs).cpu().numpy()
                all_predictions.extend(probabilities)
                all_labels.extend(batch_y.cpu().numpy())
        
        avg_loss = total_loss / len(self.val_loader)
        
        # Compute comprehensive metrics
        metrics = compute_classification_metrics(
            np.array(all_labels), 
            np.array(all_predictions)
        )
        metrics['loss'] = avg_loss
        
        return metrics

def create_client_fn(bank_datasets: Dict[str, Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]], 
                    config: Dict[str, Any]):
    """
    Create a client function for Flower simulation.
    
    Args:
        bank_datasets: Dictionary mapping bank names to datasets
        config: Configuration dictionary
        
    Returns:
        Client function for Flower
    """
    def client_fn(cid: str) -> FraudDetectionClient:
        # Map client ID to bank data
        bank_names = list(bank_datasets.keys())
        bank_name = bank_names[int(cid)]
        X_train, X_val, y_train, y_val = bank_datasets[bank_name]
        
        return FraudDetectionClient(
            client_id=bank_name,
            X_train=X_train,
            y_train=y_train,
            X_val=X_val,
            y_val=y_val,
            config=config
        )
    
    return client_fn

class FederatedTrainingServer:
    """
    Custom server for federated training with enhanced logging and metrics.
    """
    
    def __init__(self, config: Dict[str, Any], global_test_data: Optional[Tuple[np.ndarray, np.ndarray]] = None):
        """
        Initialize the federated training server.
        
        Args:
            config: Configuration dictionary
            global_test_data: Optional global test dataset for evaluation
        """
        self.config = config
        self.global_test_data = global_test_data
        self.device = get_device(config)
        
        # Initialize global model for evaluation
        if global_test_data is not None:
            self.global_model = build_model(global_test_data[0].shape[1], config)
            self.global_model.to(self.device)
        
        # Training history
        self.training_history = []
        self.round_metrics = []
        
        # Create strategy
        self.strategy = self._create_strategy()
        
        logger.info("Initialized federated training server")
    
    def _create_strategy(self) -> fl.server.strategy.Strategy:
        """
        Create the federated learning strategy.
        
        Returns:
            Flower strategy
        """
        fl_config = self.config['federated_learning']
        strategy_name = fl_config.get('strategy', 'FedAvg')
        
        # Common strategy parameters
        strategy_params = {
            'min_fit_clients': fl_config['min_fit_clients'],
            'min_evaluate_clients': fl_config['min_evaluate_clients'],
            'min_available_clients': fl_config['min_available_clients'],
            'evaluate_fn': self._get_evaluate_fn(),
            'on_fit_config_fn': self._get_fit_config_fn(),
            'on_evaluate_config_fn': self._get_evaluate_config_fn(),
        }
        
        if strategy_name == 'FedAvg':
            strategy = FedAvg(**strategy_params)
        elif strategy_name == 'FedProx':
            strategy_params['proximal_mu'] = fl_config.get('fedprox_proximal_mu', 0.01)
            strategy = FedProx(**strategy_params)
        elif strategy_name == 'FedOpt':
            strategy = FedOpt(**strategy_params)
        else:
            raise ValueError(f"Unknown strategy: {strategy_name}")
        
        logger.info(f"Created {strategy_name} strategy")
        return strategy
    
    def _get_fit_config_fn(self):
        """Get fit configuration function."""
        def fit_config(round_num: int) -> Dict[str, Any]:
            return {
                'round': round_num,
                'local_epochs': self.config['model']['local_epochs'],
                'batch_size': self.config['model']['batch_size'],
                'learning_rate': self.config['model']['learning_rate']
            }
        return fit_config
    
    def _get_evaluate_config_fn(self):
        """Get evaluate configuration function."""
        def evaluate_config(round_num: int) -> Dict[str, Any]:
            return {
                'round': round_num,
                'batch_size': self.config['model']['batch_size']
            }
        return evaluate_config
    
    def _get_evaluate_fn(self):
        """Get global evaluation function."""
        if self.global_test_data is None:
            return None
        
        def evaluate(round_num: int, parameters: Parameters, config: Dict[str, Any]) -> Optional[Tuple[float, Dict[str, Any]]]:
            # Set global model parameters
            params_list = fl.common.parameters_to_ndarrays(parameters)
            params_dict = zip(self.global_model.state_dict().keys(), params_list)
            state_dict = OrderedDict({k: torch.tensor(v) for k, v in params_dict})
            self.global_model.load_state_dict(state_dict, strict=True)
            
            # Evaluate on global test set
            X_test, y_test = self.global_test_data
            from .data_utils import create_data_loaders
            test_loader = create_data_loaders(X_test, y_test, 
                                            batch_size=self.config['model']['batch_size'],
                                            shuffle=False)
            
            self.global_model.eval()
            total_loss = 0.0
            all_predictions = []
            all_labels = []
            
            criterion = nn.BCEWithLogitsLoss()
            
            with torch.no_grad():
                for batch_X, batch_y in test_loader:
                    batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                    
                    outputs = self.global_model(batch_X).squeeze()
                    loss = criterion(outputs, batch_y)
                    
                    total_loss += loss.item()
                    
                    probabilities = torch.sigmoid(outputs).cpu().numpy()
                    all_predictions.extend(probabilities)
                    all_labels.extend(batch_y.cpu().numpy())
            
            avg_loss = total_loss / len(test_loader)
            
            # Compute metrics
            metrics = compute_classification_metrics(
                np.array(all_labels),
                np.array(all_predictions)
            )
            metrics['loss'] = avg_loss
            metrics['round'] = round_num
            
            # Store round metrics
            self.round_metrics.append(metrics)
            
            logger.info(f"Round {round_num} global evaluation: "
                       f"loss={avg_loss:.4f}, auc={metrics['auc']:.4f}")
            
            return avg_loss, metrics
        
        return evaluate

def run_federated_training(config: Dict[str, Any], bank_datasets: Dict[str, Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]], 
                          global_test_data: Optional[Tuple[np.ndarray, np.ndarray]] = None) -> Dict[str, Any]:
    """
    Run federated training using Flower.
    
    Args:
        config: Configuration dictionary
        bank_datasets: Dictionary mapping bank names to datasets
        global_test_data: Optional global test dataset
        
    Returns:
        Training results and metrics
    """
    logger.info("Starting federated training")
    
    # Create server
    server = FederatedTrainingServer(config, global_test_data)
    
    # Create client function
    client_fn = create_client_fn(bank_datasets, config)
    
    # Run simulation
    fl_config = config['federated_learning']
    history = fl.simulation.start_simulation(
        client_fn=client_fn,
        num_clients=len(bank_datasets),
        config=fl.server.ServerConfig(num_rounds=fl_config['num_rounds']),
        strategy=server.strategy,
        client_resources={'num_cpus': 1, 'num_gpus': 0}
    )
    
    # Compile results
    results = {
        'history': history,
        'round_metrics': server.round_metrics,
        'config': config,
        'num_rounds': fl_config['num_rounds'],
        'num_clients': len(bank_datasets)
    }
    
    logger.info("Federated training completed")
    
    return results

def save_federated_results(results: Dict[str, Any], filepath: str) -> None:
    """
    Save federated training results.
    
    Args:
        results: Training results dictionary
        filepath: Path to save results
    """
    import pickle
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'wb') as f:
        pickle.dump(results, f)
    
    logger.info(f"Federated training results saved to: {filepath}")

def load_federated_results(filepath: str) -> Dict[str, Any]:
    """
    Load federated training results.
    
    Args:
        filepath: Path to load results from
        
    Returns:
        Training results dictionary
    """
    import pickle
    
    with open(filepath, 'rb') as f:
        results = pickle.load(f)
    
    logger.info(f"Federated training results loaded from: {filepath}")
    
    return results

def aggregate_client_metrics(client_metrics: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Aggregate metrics from multiple clients.
    
    Args:
        client_metrics: List of client metric dictionaries
        
    Returns:
        Aggregated metrics
    """
    if not client_metrics:
        return {}
    
    # Initialize aggregated metrics
    aggregated = {}
    
    # Numeric metrics to average
    numeric_metrics = ['train_loss', 'train_accuracy', 'loss', 'accuracy', 'auc', 'precision', 'recall', 'f1']
    
    for metric in numeric_metrics:
        values = [m.get(metric, 0) for m in client_metrics if metric in m]
        if values:
            aggregated[f'avg_{metric}'] = np.mean(values)
            aggregated[f'std_{metric}'] = np.std(values)
            aggregated[f'min_{metric}'] = np.min(values)
            aggregated[f'max_{metric}'] = np.max(values)
    
    # Total number of examples
    aggregated['total_examples'] = sum(m.get('num_examples', 0) for m in client_metrics)
    
    return aggregated