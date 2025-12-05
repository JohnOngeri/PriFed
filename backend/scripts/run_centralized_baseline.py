"""
Run centralized baseline training for fraud detection.
Trains a single model on the combined dataset from all banks.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
import numpy as np
import pandas as pd
import logging
from datetime import datetime
import argparse
import json

from utils.data_utils import load_config, prepare_centralized_dataset, create_data_loaders
from utils.model_utils import build_model, save_model, get_device
from utils.metrics_utils import compute_classification_metrics, MetricsTracker
from utils.viz_utils import plot_training_history, plot_confusion_matrix, plot_roc_curve

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/centralized_training.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def train_epoch(model, train_loader, criterion, optimizer, device):
    """
    Train model for one epoch.
    
    Args:
        model: PyTorch model
        train_loader: Training data loader
        criterion: Loss function
        optimizer: Optimizer
        device: Device to train on
        
    Returns:
        Average loss and accuracy for the epoch
    """
    model.train()
    total_loss = 0.0
    correct_predictions = 0
    total_samples = 0
    
    for batch_X, batch_y in train_loader:
        batch_X, batch_y = batch_X.to(device), batch_y.to(device)
        
        # Forward pass
        optimizer.zero_grad()
        outputs = model(batch_X).squeeze()
        loss = criterion(outputs, batch_y)
        
        # Backward pass
        loss.backward()
        optimizer.step()
        
        # Statistics
        total_loss += loss.item()
        predictions = torch.sigmoid(outputs) > 0.5
        correct_predictions += (predictions == batch_y).sum().item()
        total_samples += batch_y.size(0)
    
    avg_loss = total_loss / len(train_loader)
    accuracy = correct_predictions / total_samples
    
    return avg_loss, accuracy

def evaluate_model(model, data_loader, criterion, device):
    """
    Evaluate model on validation/test data.
    
    Args:
        model: PyTorch model
        data_loader: Data loader
        criterion: Loss function
        device: Device to evaluate on
        
    Returns:
        Loss, predictions, and labels
    """
    model.eval()
    total_loss = 0.0
    all_predictions = []
    all_labels = []
    
    with torch.no_grad():
        for batch_X, batch_y in data_loader:
            batch_X, batch_y = batch_X.to(device), batch_y.to(device)
            
            outputs = model(batch_X).squeeze()
            loss = criterion(outputs, batch_y)
            
            total_loss += loss.item()
            
            # Store predictions and labels
            probabilities = torch.sigmoid(outputs).cpu().numpy()
            all_predictions.extend(probabilities)
            all_labels.extend(batch_y.cpu().numpy())
    
    avg_loss = total_loss / len(data_loader)
    
    return avg_loss, np.array(all_predictions), np.array(all_labels)

def run_centralized_training(config):
    """
    Run centralized training experiment.
    
    Args:
        config: Configuration dictionary
    """
    logger.info("Starting centralized baseline training")
    
    # Set random seeds for reproducibility
    torch.manual_seed(config['experiment']['seed'])
    np.random.seed(config['experiment']['seed'])
    
    # Get device
    device = get_device(config)
    logger.info(f"Using device: {device}")
    
    # Prepare data
    logger.info("Preparing centralized dataset...")
    X_train, X_val, X_test, y_train, y_val, y_test, scalers, encoders = prepare_centralized_dataset(config)
    
    # Create data loaders
    batch_size = config['model']['batch_size']
    train_loader = create_data_loaders(X_train, y_train, batch_size, shuffle=True)
    val_loader = create_data_loaders(X_val, y_val, batch_size, shuffle=False)
    test_loader = create_data_loaders(X_test, y_test, batch_size, shuffle=False)
    
    logger.info(f"Training samples: {len(X_train)}")
    logger.info(f"Validation samples: {len(X_val)}")
    logger.info(f"Test samples: {len(X_test)}")
    logger.info(f"Features: {X_train.shape[1]}")
    
    # Build model
    model = build_model(X_train.shape[1], config)
    model.to(device)
    
    # Loss function and optimizer
    criterion = nn.BCEWithLogitsLoss()
    optimizer = optim.Adam(
        model.parameters(),
        lr=config['model']['learning_rate'],
        weight_decay=config['model']['weight_decay']
    )
    
    # Learning rate scheduler
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode='min', factor=0.5, patience=5, verbose=True
    )
    
    # Training loop
    num_epochs = config['model'].get('epochs', 50)
    best_val_auc = 0.0
    patience = 10
    patience_counter = 0
    
    training_history = []
    
    logger.info(f"Starting training for {num_epochs} epochs...")
    
    for epoch in range(num_epochs):
        start_time = datetime.now()
        
        # Train
        train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer, device)
        
        # Validate
        val_loss, val_predictions, val_labels = evaluate_model(model, val_loader, criterion, device)
        val_metrics = compute_classification_metrics(val_labels, val_predictions)
        
        # Learning rate scheduling
        scheduler.step(val_loss)
        
        # Log metrics
        epoch_time = (datetime.now() - start_time).total_seconds()
        
        epoch_metrics = {
            'epoch': epoch + 1,
            'train_loss': train_loss,
            'train_accuracy': train_acc,
            'val_loss': val_loss,
            'val_accuracy': val_metrics['accuracy'],
            'val_auc': val_metrics['auc'],
            'val_precision': val_metrics['precision'],
            'val_recall': val_metrics['recall'],
            'val_f1': val_metrics['f1'],
            'epoch_time': epoch_time,
            'learning_rate': optimizer.param_groups[0]['lr']
        }
        
        training_history.append(epoch_metrics)
        
        logger.info(f"Epoch {epoch+1}/{num_epochs}: "
                   f"Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.4f}, "
                   f"Val Loss: {val_loss:.4f}, Val AUC: {val_metrics['auc']:.4f}")
        
        # Early stopping
        if val_metrics['auc'] > best_val_auc:
            best_val_auc = val_metrics['auc']
            patience_counter = 0
            
            # Save best model
            save_model(
                model, 
                'models/centralized_best_model.pth',
                metadata={
                    'epoch': epoch + 1,
                    'val_auc': best_val_auc,
                    'config': config,
                    'scalers': scalers,
                    'encoders': encoders
                }
            )
        else:
            patience_counter += 1
            
        if patience_counter >= patience:
            logger.info(f"Early stopping at epoch {epoch+1}")
            break
    
    # Load best model for final evaluation
    model, metadata = torch.load('models/centralized_best_model.pth', map_location=device)
    model.to(device)
    
    # Final evaluation on test set
    logger.info("Evaluating on test set...")
    test_loss, test_predictions, test_labels = evaluate_model(model, test_loader, criterion, device)
    test_metrics = compute_classification_metrics(test_labels, test_predictions)
    
    logger.info("Test Results:")
    logger.info(f"  Loss: {test_loss:.4f}")
    logger.info(f"  Accuracy: {test_metrics['accuracy']:.4f}")
    logger.info(f"  AUC: {test_metrics['auc']:.4f}")
    logger.info(f"  Precision: {test_metrics['precision']:.4f}")
    logger.info(f"  Recall: {test_metrics['recall']:.4f}")
    logger.info(f"  F1: {test_metrics['f1']:.4f}")
    
    # Save results
    results = {
        'experiment_type': 'centralized_baseline',
        'config': config,
        'training_history': training_history,
        'test_metrics': test_metrics,
        'best_val_auc': best_val_auc,
        'total_epochs': len(training_history),
        'dataset_info': {
            'train_samples': len(X_train),
            'val_samples': len(X_val),
            'test_samples': len(X_test),
            'features': X_train.shape[1],
            'fraud_rate_train': float(y_train.mean()),
            'fraud_rate_val': float(y_val.mean()),
            'fraud_rate_test': float(y_test.mean())
        },
        'timestamp': datetime.now().isoformat()
    }
    
    # Save results to JSON
    os.makedirs('results', exist_ok=True)
    with open('results/centralized_baseline_results.json', 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    # Save metrics to CSV
    metrics_df = pd.DataFrame(training_history)
    metrics_df.to_csv('results/centralized_training_history.csv', index=False)
    
    # Generate visualizations
    logger.info("Generating visualizations...")
    
    # Training history plot
    plot_training_history(
        training_history,
        save_path='results/centralized_training_history.png'
    )
    
    # Test set evaluation plots
    test_predictions_binary = (test_predictions > 0.5).astype(int)
    
    plot_confusion_matrix(
        test_labels, test_predictions_binary,
        save_path='results/centralized_confusion_matrix.png'
    )
    
    plot_roc_curve(
        test_labels, test_predictions,
        save_path='results/centralized_roc_curve.png'
    )
    
    logger.info("Centralized baseline training completed successfully!")
    logger.info(f"Results saved to: results/centralized_baseline_results.json")
    
    return results

def main():
    """Main function."""
    parser = argparse.ArgumentParser(description='Run centralized baseline training')
    parser.add_argument('--config', type=str, default='configs/config.yaml',
                       help='Path to configuration file')
    parser.add_argument('--epochs', type=int, help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, help='Batch size')
    parser.add_argument('--lr', type=float, help='Learning rate')
    
    args = parser.parse_args()
    
    # Load configuration
    config = load_config(args.config)
    
    # Override config with command line arguments
    if args.epochs:
        config['model']['epochs'] = args.epochs
    if args.batch_size:
        config['model']['batch_size'] = args.batch_size
    if args.lr:
        config['model']['learning_rate'] = args.lr
    
    # Create necessary directories
    os.makedirs('logs', exist_ok=True)
    os.makedirs('models', exist_ok=True)
    os.makedirs('results', exist_ok=True)
    
    try:
        results = run_centralized_training(config)
        print(f"\nCentralized training completed successfully!")
        print(f"Final test AUC: {results['test_metrics']['auc']:.4f}")
        
    except Exception as e:
        logger.error(f"Training failed: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()