"""
Run federated learning training for fraud detection.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import torch
import numpy as np
import logging
from datetime import datetime
import argparse
import json

from utils.data_utils import load_config, prepare_local_datasets_for_banks, prepare_global_test_set
from utils.fl_utils import run_federated_training
from utils.metrics_utils import MetricsTracker
from utils.viz_utils import generate_all_plots

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    parser = argparse.ArgumentParser(description='Run federated training')
    parser.add_argument('--config', type=str, default='configs/config.yaml')
    parser.add_argument('--rounds', type=int, help='Number of FL rounds')
    args = parser.parse_args()
    
    config = load_config(args.config)
    if args.rounds:
        config['federated_learning']['num_rounds'] = args.rounds
    
    os.makedirs('logs', exist_ok=True)
    os.makedirs('models', exist_ok=True)
    os.makedirs('results', exist_ok=True)
    
    logger.info("Starting federated training")
    
    # Prepare data
    bank_datasets = prepare_local_datasets_for_banks(config)
    X_test, y_test = prepare_global_test_set(config)
    
    # Run federated training
    results = run_federated_training(config, bank_datasets, (X_test, y_test))
    
    # Save results
    with open('results/federated_results.json', 'w') as f:
        json.dump({
            'experiment_type': 'federated_learning',
            'config': config,
            'results': results,
            'timestamp': datetime.now().isoformat()
        }, f, indent=2, default=str)
    
    # Generate plots
    generate_all_plots('results', results.get('round_metrics', []), {}, {})
    
    logger.info("Federated training completed")

if __name__ == "__main__":
    main()