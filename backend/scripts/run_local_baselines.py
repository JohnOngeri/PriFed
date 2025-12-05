"""
Run local baseline training for individual banks.
Trains separate models for each bank using only their local data.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
import pandas as pd
import logging
from datetime import datetime
import argparse
import json

from utils.data_utils import load_config, prepare_local_datasets_for_banks, create_data_loaders
from utils.model_utils import build_model, save_model, get_device
from utils.metrics_utils import compute_classification_metrics, MetricsTracker

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def train_local_model(bank_name, X_train, y_train, X_val, y_val, config, device):
    """Train a local model for a specific bank."""
    logger.info(f"Training local model for {bank_name}")
    
    # Create data loaders
    train_loader = create_data_loaders(X_train, y_train, config['model']['batch_size'], shuffle=True)
    val_loader = create_data_loaders(X_val, y_val, config['model']['batch_size'], shuffle=False)
    
    # Build model
    model = build_model(X_train.shape[1], config)
    model.to(device)
    
    # Optimizer and loss
    optimizer = optim.Adam(model.parameters(), lr=config['model']['learning_rate'])
    criterion = nn.BCEWithLogitsLoss()
    
    # Training loop
    num_epochs = config['model'].get('epochs', 20)
    best_auc = 0.0
    training_history = []
    
    for epoch in range(num_epochs):
        # Train
        model.train()
        train_loss = 0.0
        for batch_X, batch_y in train_loader:
            batch_X, batch_y = batch_X.to(device), batch_y.to(device)
            
            optimizer.zero_grad()
            outputs = model(batch_X).squeeze()
            loss = criterion(outputs, batch_y)
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
        
        # Validate
        model.eval()
        val_predictions = []
        val_labels = []
        val_loss = 0.0
        
        with torch.no_grad():
            for batch_X, batch_y in val_loader:
                batch_X, batch_y = batch_X.to(device), batch_y.to(device)
                outputs = model(batch_X).squeeze()
                loss = criterion(outputs, batch_y)
                val_loss += loss.item()
                
                probs = torch.sigmoid(outputs).cpu().numpy()
                val_predictions.extend(probs)
                val_labels.extend(batch_y.cpu().numpy())
        
        # Compute metrics
        metrics = compute_classification_metrics(np.array(val_labels), np.array(val_predictions))
        
        epoch_metrics = {
            'epoch': epoch + 1,
            'train_loss': train_loss / len(train_loader),
            'val_loss': val_loss / len(val_loader),
            'val_auc': metrics['auc'],
            'val_accuracy': metrics['accuracy'],
            'val_precision': metrics['precision'],
            'val_recall': metrics['recall'],
            'val_f1': metrics['f1']
        }
        
        training_history.append(epoch_metrics)
        
        if metrics['auc'] > best_auc:
            best_auc = metrics['auc']
            save_model(model, f'models/{bank_name}_best_model.pth', metadata={'epoch': epoch + 1, 'auc': best_auc})
        
        if epoch % 5 == 0:
            logger.info(f"{bank_name} Epoch {epoch+1}: AUC={metrics['auc']:.4f}, Loss={val_loss/len(val_loader):.4f}")
    
    return model, training_history, best_auc

def main():
    parser = argparse.ArgumentParser(description='Run local baseline training')
    parser.add_argument('--config', type=str, default='configs/config.yaml')
    args = parser.parse_args()
    
    config = load_config(args.config)
    device = get_device(config)
    
    os.makedirs('models', exist_ok=True)
    os.makedirs('results', exist_ok=True)
    
    logger.info("Starting local baseline training for all banks")
    
    # Prepare bank datasets
    bank_datasets = prepare_local_datasets_for_banks(config)
    
    all_results = {}
    all_histories = {}
    
    # Train each bank individually
    for bank_name, (X_train, X_val, y_train, y_val) in bank_datasets.items():
        model, history, best_auc = train_local_model(
            bank_name, X_train, y_train, X_val, y_val, config, device
        )
        
        all_results[bank_name] = {
            'best_auc': best_auc,
            'num_samples': len(X_train),
            'fraud_rate': float(y_train.mean())
        }
        all_histories[bank_name] = history
        
        logger.info(f"{bank_name} completed: Best AUC = {best_auc:.4f}")
    
    # Save results
    results = {
        'experiment_type': 'local_baselines',
        'config': config,
        'bank_results': all_results,
        'training_histories': all_histories,
        'timestamp': datetime.now().isoformat()
    }
    
    with open('results/local_baselines_results.json', 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    # Save metrics to CSV
    all_metrics = []
    for bank_name, history in all_histories.items():
        for epoch_metrics in history:
            epoch_metrics['bank'] = bank_name
            all_metrics.append(epoch_metrics)
    
    pd.DataFrame(all_metrics).to_csv('results/local_baselines_history.csv', index=False)
    
    logger.info("Local baseline training completed successfully!")
    logger.info(f"Results saved to: results/local_baselines_results.json")
    
    # Print summary
    print("\nLocal Baseline Results Summary:")
    for bank_name, results in all_results.items():
        print(f"{bank_name}: AUC={results['best_auc']:.4f}, Samples={results['num_samples']}")

if __name__ == "__main__":
    main()