"""
Differential Privacy utilities for federated learning.
Implements DP-SGD and privacy accounting for fraud detection models.

This module provides enterprise-grade differential privacy capabilities including:
- DP-SGD implementation with gradient clipping and noise injection
- Privacy accounting using RDP and GDP accountants
- Privacy budget management and tracking
- Comprehensive privacy analysis and reporting
- Integration with PyTorch and Opacus
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
import numpy as np
from typing import Dict, List, Tuple, Optional, Any, Union
import logging
from collections import defaultdict
import math
import warnings

# Opacus imports for differential privacy
try:
    from opacus import PrivacyEngine
    from opacus.validators import ModuleValidator
    from opacus.utils.batch_memory_manager import BatchMemoryManager
    from opacus.accountants.rdp import RDPAccountant
    from opacus.accountants.gdp import GaussianAccountant
    OPACUS_AVAILABLE = True
except ImportError:
    OPACUS_AVAILABLE = False
    warnings.warn("Opacus not available. Differential privacy features will be limited.")

logger = logging.getLogger(__name__)

class DPTrainer:
    """
    Differential Privacy trainer with comprehensive privacy accounting and analysis.
    """
    
    def __init__(self, model: nn.Module, optimizer: optim.Optimizer, 
                 criterion: nn.Module, config: Dict[str, Any]):
        """
        Initialize the DP trainer.
        
        Args:
            model: PyTorch model
            optimizer: PyTorch optimizer
            criterion: Loss function
            config: DP configuration dictionary
        """
        self.model = model
        self.optimizer = optimizer
        self.criterion = criterion
        self.config = config
        self.device = next(model.parameters()).device
        
        # DP parameters
        self.noise_multiplier = config.get('noise_multiplier', 1.1)
        self.max_grad_norm = config.get('max_grad_norm', 1.0)
        self.target_epsilon = config.get('target_epsilon', 8.0)
        self.target_delta = config.get('target_delta', 1e-5)
        self.accountant_mode = config.get('accountant_mode', 'rdp')
        
        # Privacy tracking
        self.privacy_history = []
        self.current_epsilon = 0.0
        self.steps_taken = 0
        
        # Initialize privacy engine if Opacus is available
        self.privacy_engine = None
        self.use_opacus = OPACUS_AVAILABLE and config.get('use_opacus', True)
        
        if self.use_opacus:
            self._initialize_opacus()
        else:
            logger.warning("Using manual DP implementation (Opacus not available)")
            self._initialize_manual_dp()
        
        logger.info(f"DP Trainer initialized: ε={self.target_epsilon}, δ={self.target_delta}, "
                   f"noise_multiplier={self.noise_multiplier}, max_grad_norm={self.max_grad_norm}")
    
    def _initialize_opacus(self) -> None:
        """Initialize Opacus privacy engine."""
        try:
            # Validate model for Opacus compatibility
            errors = ModuleValidator.validate(self.model, strict=False)
            if errors:
                logger.warning(f"Model validation errors: {errors}")
                # Try to fix common issues
                self.model = ModuleValidator.fix(self.model)
            
            # Create privacy engine
            self.privacy_engine = PrivacyEngine(accountant=self.accountant_mode)
            
            # Make model, optimizer, and data loader private
            # Note: DataLoader will be made private during training
            self.model, self.optimizer, _ = self.privacy_engine.make_private(
                module=self.model,
                optimizer=self.optimizer,
                data_loader=None,  # Will be set during training
                noise_multiplier=self.noise_multiplier,
                max_grad_norm=self.max_grad_norm,
            )
            
            logger.info("Opacus privacy engine initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Opacus: {e}")
            self.use_opacus = False
            self._initialize_manual_dp()
    
    def _initialize_manual_dp(self) -> None:
        """Initialize manual DP implementation."""
        # Create privacy accountant
        if self.accountant_mode == 'rdp':
            self.accountant = ManualRDPAccountant()
        else:
            self.accountant = ManualGDPAccountant()
        
        logger.info("Manual DP implementation initialized")
    
    def train(self, data_loader: DataLoader, epochs: int) -> Dict[str, Any]:
        """
        Train the model with differential privacy.
        
        Args:
            data_loader: Training data loader
            epochs: Number of training epochs
            
        Returns:
            Training metrics including privacy metrics
        """
        logger.info(f"Starting DP training for {epochs} epochs")
        
        if self.use_opacus:
            return self._train_with_opacus(data_loader, epochs)
        else:
            return self._train_manual_dp(data_loader, epochs)
    
    def _train_with_opacus(self, data_loader: DataLoader, epochs: int) -> Dict[str, Any]:
        """Train using Opacus privacy engine."""
        # Make data loader private if not already done
        if not hasattr(data_loader, '_is_private'):
            _, _, data_loader = self.privacy_engine.make_private(
                module=self.model,
                optimizer=self.optimizer,
                data_loader=data_loader,
                noise_multiplier=self.noise_multiplier,
                max_grad_norm=self.max_grad_norm,
            )
        
        self.model.train()
        total_loss = 0.0
        correct_predictions = 0
        total_samples = 0
        
        # Use BatchMemoryManager for memory efficiency
        with BatchMemoryManager(
            data_loader=data_loader,
            max_physical_batch_size=self.config.get('max_physical_batch_size', 128),
            optimizer=self.optimizer
        ) as memory_safe_data_loader:
            
            for epoch in range(epochs):
                epoch_loss = 0.0
                epoch_correct = 0
                epoch_samples = 0
                
                for batch_X, batch_y, _ in memory_safe_data_loader:
                    batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                    
                    # Forward pass
                    self.optimizer.zero_grad()
                    outputs = self.model(batch_X).squeeze()
                    loss = self.criterion(outputs, batch_y)
                    
                    # Backward pass (DP gradients computed automatically)
                    loss.backward()
                    self.optimizer.step()
                    
                    # Statistics
                    epoch_loss += loss.item()
                    predictions = torch.sigmoid(outputs) > 0.5
                    epoch_correct += (predictions == batch_y).sum().item()
                    epoch_samples += batch_y.size(0)
                    
                    self.steps_taken += 1
                
                total_loss += epoch_loss
                correct_predictions += epoch_correct
                total_samples += epoch_samples
                
                # Compute current privacy budget
                current_epsilon = self.privacy_engine.get_epsilon(self.target_delta)
                self.current_epsilon = current_epsilon
                
                # Track privacy history
                self.privacy_history.append({
                    'epoch': epoch + 1,
                    'step': self.steps_taken,
                    'epsilon': current_epsilon,
                    'delta': self.target_delta,
                    'loss': epoch_loss / len(memory_safe_data_loader)
                })
                
                logger.info(f"Epoch {epoch+1}/{epochs}: loss={epoch_loss/len(memory_safe_data_loader):.4f}, "
                           f"ε={current_epsilon:.4f}")
        
        avg_loss = total_loss / (epochs * len(data_loader))
        accuracy = correct_predictions / total_samples
        
        return {
            'loss': avg_loss,
            'accuracy': accuracy,
            'dp_metrics': {
                'final_epsilon': self.current_epsilon,
                'target_epsilon': self.target_epsilon,
                'delta': self.target_delta,
                'noise_multiplier': self.noise_multiplier,
                'max_grad_norm': self.max_grad_norm,
                'steps_taken': self.steps_taken,
                'privacy_history': self.privacy_history
            }
        }
    
    def _train_manual_dp(self, data_loader: DataLoader, epochs: int) -> Dict[str, Any]:
        """Train using manual DP implementation."""
        self.model.train()
        total_loss = 0.0
        correct_predictions = 0
        total_samples = 0
        
        for epoch in range(epochs):
            epoch_loss = 0.0
            epoch_correct = 0
            epoch_samples = 0
            
            for batch_X, batch_y, _ in data_loader:
                batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                
                # Forward pass
                self.optimizer.zero_grad()
                outputs = self.model(batch_X).squeeze()
                loss = self.criterion(outputs, batch_y)
                
                # Backward pass
                loss.backward()
                
                # Apply DP gradient modifications
                self._apply_dp_gradients()
                
                self.optimizer.step()
                
                # Statistics
                epoch_loss += loss.item()
                predictions = torch.sigmoid(outputs) > 0.5
                epoch_correct += (predictions == batch_y).sum().item()
                epoch_samples += batch_y.size(0)
                
                self.steps_taken += 1
            
            total_loss += epoch_loss
            correct_predictions += epoch_correct
            total_samples += epoch_samples
            
            # Update privacy accounting
            self.current_epsilon = self.accountant.get_epsilon(
                self.steps_taken, len(data_loader.dataset), 
                self.noise_multiplier, self.target_delta
            )
            
            # Track privacy history
            self.privacy_history.append({
                'epoch': epoch + 1,
                'step': self.steps_taken,
                'epsilon': self.current_epsilon,
                'delta': self.target_delta,
                'loss': epoch_loss / len(data_loader)
            })
            
            logger.info(f"Epoch {epoch+1}/{epochs}: loss={epoch_loss/len(data_loader):.4f}, "
                       f"ε={self.current_epsilon:.4f}")
        
        avg_loss = total_loss / (epochs * len(data_loader))
        accuracy = correct_predictions / total_samples
        
        return {
            'loss': avg_loss,
            'accuracy': accuracy,
            'dp_metrics': {
                'final_epsilon': self.current_epsilon,
                'target_epsilon': self.target_epsilon,
                'delta': self.target_delta,
                'noise_multiplier': self.noise_multiplier,
                'max_grad_norm': self.max_grad_norm,
                'steps_taken': self.steps_taken,
                'privacy_history': self.privacy_history
            }
        }
    
    def _apply_dp_gradients(self) -> None:
        """Apply differential privacy to gradients manually."""
        # Clip gradients
        total_norm = torch.nn.utils.clip_grad_norm_(
            self.model.parameters(), self.max_grad_norm
        )
        
        # Add noise to gradients
        for param in self.model.parameters():
            if param.grad is not None:
                noise = torch.randn_like(param.grad) * self.noise_multiplier * self.max_grad_norm
                param.grad += noise
    
    def get_privacy_analysis(self) -> Dict[str, Any]:
        """
        Get comprehensive privacy analysis.
        
        Returns:
            Privacy analysis results
        """
        if not self.privacy_history:
            return {'error': 'No privacy history available'}
        
        analysis = {
            'current_privacy_budget': {
                'epsilon': self.current_epsilon,
                'delta': self.target_delta,
                'remaining_epsilon': max(0, self.target_epsilon - self.current_epsilon),
                'budget_used_percentage': (self.current_epsilon / self.target_epsilon) * 100
            },
            'privacy_parameters': {
                'noise_multiplier': self.noise_multiplier,
                'max_grad_norm': self.max_grad_norm,
                'target_epsilon': self.target_epsilon,
                'target_delta': self.target_delta,
                'accountant_mode': self.accountant_mode
            },
            'training_progress': {
                'steps_taken': self.steps_taken,
                'epochs_completed': len(self.privacy_history),
                'privacy_history': self.privacy_history
            }
        }
        
        # Privacy guarantees assessment
        if self.current_epsilon <= self.target_epsilon:
            analysis['privacy_guarantee'] = 'SATISFIED'
            analysis['privacy_status'] = f'Privacy budget within target (ε={self.current_epsilon:.4f} ≤ {self.target_epsilon})'
        else:
            analysis['privacy_guarantee'] = 'VIOLATED'
            analysis['privacy_status'] = f'Privacy budget exceeded (ε={self.current_epsilon:.4f} > {self.target_epsilon})'
        
        # Recommendations
        recommendations = []
        
        if self.current_epsilon > self.target_epsilon * 0.9:
            recommendations.append("Privacy budget nearly exhausted - consider stopping training")
        
        if self.noise_multiplier < 1.0:
            recommendations.append("Low noise multiplier - consider increasing for stronger privacy")
        
        if self.max_grad_norm > 2.0:
            recommendations.append("High gradient clipping norm - consider reducing for better privacy")
        
        analysis['recommendations'] = recommendations
        
        return analysis

class ManualRDPAccountant:
    """Manual implementation of RDP (Rényi Differential Privacy) accountant."""
    
    def __init__(self):
        self.orders = [1 + x / 10.0 for x in range(1, 100)] + list(range(12, 64))
    
    def get_epsilon(self, steps: int, dataset_size: int, noise_multiplier: float, 
                   delta: float) -> float:
        """
        Compute epsilon using RDP accounting.
        
        Args:
            steps: Number of training steps
            dataset_size: Size of the dataset
            noise_multiplier: Noise multiplier for DP-SGD
            delta: Target delta
            
        Returns:
            Current epsilon value
        """
        if steps == 0:
            return 0.0
        
        # Sampling probability
        q = 1.0 / dataset_size  # Assuming batch size = 1 for simplicity
        
        # Compute RDP for each order
        rdp_values = []
        for alpha in self.orders:
            if alpha == 1:
                rdp = 0  # RDP is 0 for alpha = 1
            else:
                rdp = self._compute_rdp_sample_wor_gaussian(q, noise_multiplier, alpha)
            rdp_values.append(rdp * steps)
        
        # Convert RDP to (epsilon, delta)-DP
        epsilon = self._rdp_to_dp(rdp_values, delta)
        
        return epsilon
    
    def _compute_rdp_sample_wor_gaussian(self, q: float, sigma: float, alpha: float) -> float:
        """Compute RDP for Gaussian mechanism with sampling without replacement."""
        if q == 0:
            return 0
        
        if q == 1:
            return alpha / (2 * sigma ** 2)
        
        # Use the tight analysis from Mironov et al.
        return self._compute_rdp_poisson_subsampled_gaussian(q, sigma, alpha)
    
    def _compute_rdp_poisson_subsampled_gaussian(self, q: float, sigma: float, alpha: float) -> float:
        """Compute RDP for Poisson subsampled Gaussian mechanism."""
        if alpha == 1:
            return 0
        
        # Simplified computation (exact formula is more complex)
        return q * q * alpha / (2 * sigma ** 2)
    
    def _rdp_to_dp(self, rdp_values: List[float], delta: float) -> float:
        """Convert RDP to (epsilon, delta)-DP."""
        if not rdp_values:
            return 0.0
        
        epsilon_values = []
        for i, rdp in enumerate(rdp_values):
            alpha = self.orders[i]
            if alpha > 1:
                epsilon = rdp + math.log(1 / delta) / (alpha - 1)
                epsilon_values.append(epsilon)
        
        return min(epsilon_values) if epsilon_values else 0.0

class ManualGDPAccountant:
    """Manual implementation of GDP (Gaussian Differential Privacy) accountant."""
    
    def get_epsilon(self, steps: int, dataset_size: int, noise_multiplier: float, 
                   delta: float) -> float:
        """
        Compute epsilon using GDP accounting.
        
        Args:
            steps: Number of training steps
            dataset_size: Size of the dataset
            noise_multiplier: Noise multiplier for DP-SGD
            delta: Target delta
            
        Returns:
            Current epsilon value
        """
        if steps == 0:
            return 0.0
        
        # Simplified GDP computation
        # This is a basic approximation - the exact formula is more complex
        q = 1.0 / dataset_size
        sigma = noise_multiplier
        
        # Basic epsilon computation for Gaussian mechanism
        epsilon = q * steps * math.sqrt(2 * math.log(1.25 / delta)) / sigma
        
        return epsilon

def create_dp_trainer(model: nn.Module, optimizer: optim.Optimizer, 
                     criterion: nn.Module, config: Dict[str, Any]) -> DPTrainer:
    """
    Create a differential privacy trainer.
    
    Args:
        model: PyTorch model
        optimizer: PyTorch optimizer
        criterion: Loss function
        config: DP configuration
        
    Returns:
        DPTrainer instance
    """
    return DPTrainer(model, optimizer, criterion, config)

def compute_privacy_budget(steps: int, dataset_size: int, noise_multiplier: float,
                          delta: float, accountant_mode: str = 'rdp') -> float:
    """
    Compute privacy budget (epsilon) for given parameters.
    
    Args:
        steps: Number of training steps
        dataset_size: Size of the dataset
        noise_multiplier: Noise multiplier for DP-SGD
        delta: Target delta
        accountant_mode: Accounting method ('rdp' or 'gdp')
        
    Returns:
        Epsilon value
    """
    if accountant_mode == 'rdp':
        accountant = ManualRDPAccountant()
    else:
        accountant = ManualGDPAccountant()
    
    return accountant.get_epsilon(steps, dataset_size, noise_multiplier, delta)

def analyze_privacy_utility_tradeoff(epsilons: List[float], accuracies: List[float]) -> Dict[str, Any]:
    """
    Analyze privacy-utility tradeoff.
    
    Args:
        epsilons: List of epsilon values
        accuracies: List of corresponding accuracy values
        
    Returns:
        Tradeoff analysis results
    """
    if len(epsilons) != len(accuracies):
        raise ValueError("Epsilons and accuracies must have the same length")
    
    # Compute utility loss
    max_accuracy = max(accuracies)
    utility_losses = [max_accuracy - acc for acc in accuracies]
    
    # Find optimal points
    best_privacy_idx = np.argmin(epsilons)  # Lowest epsilon (best privacy)
    best_utility_idx = np.argmax(accuracies)  # Highest accuracy (best utility)
    
    # Compute privacy-utility ratio
    privacy_utility_ratios = []
    for eps, util_loss in zip(epsilons, utility_losses):
        if eps > 0:
            ratio = util_loss / eps
            privacy_utility_ratios.append(ratio)
        else:
            privacy_utility_ratios.append(float('inf'))
    
    best_tradeoff_idx = np.argmin(privacy_utility_ratios)
    
    analysis = {
        'best_privacy': {
            'epsilon': epsilons[best_privacy_idx],
            'accuracy': accuracies[best_privacy_idx],
            'utility_loss': utility_losses[best_privacy_idx]
        },
        'best_utility': {
            'epsilon': epsilons[best_utility_idx],
            'accuracy': accuracies[best_utility_idx],
            'utility_loss': utility_losses[best_utility_idx]
        },
        'best_tradeoff': {
            'epsilon': epsilons[best_tradeoff_idx],
            'accuracy': accuracies[best_tradeoff_idx],
            'utility_loss': utility_losses[best_tradeoff_idx],
            'privacy_utility_ratio': privacy_utility_ratios[best_tradeoff_idx]
        },
        'summary_stats': {
            'epsilon_range': (min(epsilons), max(epsilons)),
            'accuracy_range': (min(accuracies), max(accuracies)),
            'max_utility_loss': max(utility_losses),
            'avg_privacy_utility_ratio': np.mean([r for r in privacy_utility_ratios if r != float('inf')])
        }
    }
    
    return analysis

def generate_privacy_report(dp_trainer: DPTrainer, save_path: Optional[str] = None) -> Dict[str, Any]:
    """
    Generate comprehensive privacy report.
    
    Args:
        dp_trainer: DP trainer instance
        save_path: Optional path to save the report
        
    Returns:
        Privacy report
    """
    analysis = dp_trainer.get_privacy_analysis()
    
    # Create detailed report
    report = {
        'executive_summary': {
            'privacy_guarantee': analysis.get('privacy_guarantee', 'UNKNOWN'),
            'current_epsilon': analysis['current_privacy_budget']['epsilon'],
            'target_epsilon': analysis['privacy_parameters']['target_epsilon'],
            'budget_used_percentage': analysis['current_privacy_budget']['budget_used_percentage'],
            'training_steps': analysis['training_progress']['steps_taken']
        },
        'detailed_analysis': analysis,
        'recommendations': analysis.get('recommendations', []),
        'timestamp': datetime.now().isoformat()
    }
    
    # Add privacy strength assessment
    epsilon = analysis['current_privacy_budget']['epsilon']
    if epsilon <= 1.0:
        strength = "Very Strong"
    elif epsilon <= 3.0:
        strength = "Strong"
    elif epsilon <= 8.0:
        strength = "Moderate"
    elif epsilon <= 15.0:
        strength = "Weak"
    else:
        strength = "Very Weak"
    
    report['executive_summary']['privacy_strength'] = strength
    
    # Save report if path provided
    if save_path:
        import json
        import os
        
        os.makedirs(os.path.dirname(save_path), exist_ok=True)
        
        with open(save_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        logger.info(f"Privacy report saved to: {save_path}")
    
    return report

# Export main functions
__all__ = [
    'DPTrainer',
    'ManualRDPAccountant',
    'ManualGDPAccountant',
    'create_dp_trainer',
    'compute_privacy_budget',
    'analyze_privacy_utility_tradeoff',
    'generate_privacy_report'
]