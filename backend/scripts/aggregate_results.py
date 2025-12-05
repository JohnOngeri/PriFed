"""
Aggregate results from different training runs into summary reports.
Combines metrics from centralized, local, federated, and DP experiments.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
import pandas as pd
import numpy as np
from datetime import datetime
import argparse
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_experiment_results(results_dir='results'):
    """Load all experiment results from JSON files."""
    experiments = {}
    
    result_files = {
        'centralized': 'centralized_baseline_results.json',
        'local': 'local_baselines_results.json', 
        'federated': 'federated_results.json',
        'federated_dp': 'federated_dp_results.json'
    }
    
    for exp_name, filename in result_files.items():
        filepath = os.path.join(results_dir, filename)
        if os.path.exists(filepath):
            try:
                with open(filepath, 'r') as f:
                    experiments[exp_name] = json.load(f)
                logger.info(f"Loaded {exp_name} results from {filename}")
            except Exception as e:
                logger.warning(f"Failed to load {filename}: {e}")
        else:
            logger.warning(f"Results file not found: {filename}")
    
    return experiments

def extract_performance_metrics(experiments):
    """Extract key performance metrics from all experiments."""
    summary = {}
    
    # Centralized baseline
    if 'centralized' in experiments:
        test_metrics = experiments['centralized'].get('test_metrics', {})
        summary['centralized'] = {
            'auc': test_metrics.get('auc', 0),
            'accuracy': test_metrics.get('accuracy', 0),
            'precision': test_metrics.get('precision', 0),
            'recall': test_metrics.get('recall', 0),
            'f1': test_metrics.get('f1', 0)
        }
    
    # Local baselines (average across banks)
    if 'local' in experiments:
        bank_results = experiments['local'].get('bank_results', {})
        if bank_results:
            aucs = [results.get('best_auc', 0) for results in bank_results.values()]
            summary['local_average'] = {
                'auc': np.mean(aucs),
                'auc_std': np.std(aucs),
                'auc_min': np.min(aucs),
                'auc_max': np.max(aucs)
            }
    
    # Federated learning
    if 'federated' in experiments:
        round_metrics = experiments['federated'].get('round_metrics', [])
        if round_metrics:
            final_metrics = round_metrics[-1]
            summary['federated'] = {
                'auc': final_metrics.get('auc', 0),
                'accuracy': final_metrics.get('accuracy', 0),
                'precision': final_metrics.get('precision', 0),
                'recall': final_metrics.get('recall', 0),
                'f1': final_metrics.get('f1', 0),
                'rounds': len(round_metrics)
            }
    
    # Federated with DP
    if 'federated_dp' in experiments:
        round_metrics = experiments['federated_dp'].get('round_metrics', [])
        if round_metrics:
            final_metrics = round_metrics[-1]
            summary['federated_dp'] = {
                'auc': final_metrics.get('auc', 0),
                'accuracy': final_metrics.get('accuracy', 0),
                'precision': final_metrics.get('precision', 0),
                'recall': final_metrics.get('recall', 0),
                'f1': final_metrics.get('f1', 0),
                'epsilon': final_metrics.get('epsilon', 0),
                'rounds': len(round_metrics)
            }
    
    return summary

def compute_privacy_utility_tradeoff(experiments):
    """Compute privacy-utility trade-off analysis."""
    tradeoff_analysis = {}
    
    if 'centralized' in experiments and 'federated_dp' in experiments:
        centralized_auc = experiments['centralized'].get('test_metrics', {}).get('auc', 0)
        
        if 'federated_dp' in experiments:
            round_metrics = experiments['federated_dp'].get('round_metrics', [])
            if round_metrics:
                final_metrics = round_metrics[-1]
                dp_auc = final_metrics.get('auc', 0)
                epsilon = final_metrics.get('epsilon', 0)
                
                tradeoff_analysis = {
                    'centralized_auc': centralized_auc,
                    'dp_auc': dp_auc,
                    'epsilon': epsilon,
                    'utility_loss': centralized_auc - dp_auc,
                    'utility_retention': (dp_auc / centralized_auc) * 100 if centralized_auc > 0 else 0
                }
    
    return tradeoff_analysis

def compute_fairness_analysis(experiments):
    """Compute fairness analysis across banks."""
    fairness_analysis = {}
    
    if 'local' in experiments:
        bank_results = experiments['local'].get('bank_results', {})
        if bank_results:
            aucs = [results.get('best_auc', 0) for results in bank_results.values()]
            fairness_analysis['local_fairness'] = {
                'auc_variance': np.var(aucs),
                'auc_std': np.std(aucs),
                'coefficient_of_variation': np.std(aucs) / np.mean(aucs) if np.mean(aucs) > 0 else 0,
                'min_max_ratio': np.min(aucs) / np.max(aucs) if np.max(aucs) > 0 else 0
            }
    
    # Add federated fairness if available
    if 'federated' in experiments:
        # This would require per-bank metrics from federated training
        # For now, we'll add a placeholder
        fairness_analysis['federated_fairness'] = {
            'note': 'Federated fairness metrics would require per-bank evaluation data'
        }
    
    return fairness_analysis

def generate_comparison_table(summary):
    """Generate a comparison table of all approaches."""
    comparison_data = []
    
    for approach, metrics in summary.items():
        if isinstance(metrics, dict) and 'auc' in metrics:
            row = {
                'Approach': approach.replace('_', ' ').title(),
                'AUC': f"{metrics['auc']:.4f}",
                'Accuracy': f"{metrics.get('accuracy', 0):.4f}",
                'Precision': f"{metrics.get('precision', 0):.4f}",
                'Recall': f"{metrics.get('recall', 0):.4f}",
                'F1': f"{metrics.get('f1', 0):.4f}"
            }
            
            if 'epsilon' in metrics:
                row['Epsilon'] = f"{metrics['epsilon']:.2f}"
            if 'rounds' in metrics:
                row['Rounds'] = str(metrics['rounds'])
                
            comparison_data.append(row)
    
    return pd.DataFrame(comparison_data)

def main():
    parser = argparse.ArgumentParser(description='Aggregate experiment results')
    parser.add_argument('--results-dir', type=str, default='results')
    parser.add_argument('--output-dir', type=str, default='results')
    args = parser.parse_args()
    
    os.makedirs(args.output_dir, exist_ok=True)
    
    logger.info("Starting results aggregation")
    
    # Load all experiment results
    experiments = load_experiment_results(args.results_dir)
    
    if not experiments:
        logger.error("No experiment results found!")
        return
    
    # Extract performance metrics
    summary = extract_performance_metrics(experiments)
    
    # Compute analyses
    privacy_analysis = compute_privacy_utility_tradeoff(experiments)
    fairness_analysis = compute_fairness_analysis(experiments)
    
    # Generate comparison table
    comparison_df = generate_comparison_table(summary)
    
    # Create comprehensive report
    report = {
        'generation_timestamp': datetime.now().isoformat(),
        'experiments_included': list(experiments.keys()),
        'performance_summary': summary,
        'privacy_utility_analysis': privacy_analysis,
        'fairness_analysis': fairness_analysis,
        'comparison_table': comparison_df.to_dict('records') if not comparison_df.empty else []
    }
    
    # Save aggregated results
    output_file = os.path.join(args.output_dir, 'aggregated_results.json')
    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2, default=str)
    
    # Save comparison table
    if not comparison_df.empty:
        comparison_file = os.path.join(args.output_dir, 'model_comparison.csv')
        comparison_df.to_csv(comparison_file, index=False)
        logger.info(f"Comparison table saved to: {comparison_file}")
    
    logger.info(f"Aggregated results saved to: {output_file}")
    
    # Print summary
    print("\n" + "="*60)
    print("EXPERIMENT RESULTS SUMMARY")
    print("="*60)
    
    if not comparison_df.empty:
        print("\nModel Performance Comparison:")
        print(comparison_df.to_string(index=False))
    
    if privacy_analysis:
        print(f"\nPrivacy-Utility Trade-off:")
        print(f"  Centralized AUC: {privacy_analysis['centralized_auc']:.4f}")
        print(f"  DP-Federated AUC: {privacy_analysis['dp_auc']:.4f}")
        print(f"  Epsilon: {privacy_analysis['epsilon']:.2f}")
        print(f"  Utility Retention: {privacy_analysis['utility_retention']:.1f}%")
    
    if fairness_analysis.get('local_fairness'):
        fairness = fairness_analysis['local_fairness']
        print(f"\nFairness Analysis (Local Models):")
        print(f"  AUC Variance: {fairness['auc_variance']:.6f}")
        print(f"  Coefficient of Variation: {fairness['coefficient_of_variation']:.4f}")
        print(f"  Min/Max Ratio: {fairness['min_max_ratio']:.4f}")
    
    print("\n" + "="*60)

if __name__ == "__main__":
    main()