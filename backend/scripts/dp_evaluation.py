#!/usr/bin/env python3
"""
Differential Privacy Evaluation Script for PrivFed.
Analyzes privacy-utility tradeoffs across different epsilon values.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import torch
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import logging
from datetime import datetime
import argparse
import json
from typing import Dict, List, Tuple, Any
import concurrent.futures
from pathlib import Path

from utils.data_utils import load_config, prepare_centralized_dataset
from utils.model_utils import build_model, get_device
from utils.fl_utils import run_federated_training
from utils.dp_utils import DPTrainer, PrivacyAccountant
from utils.metrics_utils import compute_classification_metrics, MetricsTracker
from utils.viz_utils import plot_privacy_vs_accuracy, generate_all_plots

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DPEvaluationSuite:
    """Comprehensive differential privacy evaluation suite."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.device = get_device(config)
        self.results = {}
        self.epsilon_values = [1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0]
        
    def run_comprehensive_evaluation(self) -> Dict[str, Any]:
        """Run comprehensive DP evaluation across multiple epsilon values."""
        logger.info("Starting comprehensive differential privacy evaluation")
        
        # Prepare data once
        logger.info("Preparing dataset...")
        X_train, X_val, X_test, y_train, y_val, y_test, preprocessing_artifacts = prepare_centralized_dataset(self.config)
        
        # Store data for reuse
        self.data = {
            'X_train': X_train, 'X_val': X_val, 'X_test': X_test,
            'y_train': y_train, 'y_val': y_val, 'y_test': y_test,
            'preprocessing_artifacts': preprocessing_artifacts
        }
        
        # Run baseline (no DP)
        logger.info("Running baseline (no differential privacy)...")
        baseline_results = self._run_baseline_training()
        self.results['baseline'] = baseline_results
        
        # Run DP experiments in parallel
        logger.info(f"Running DP experiments for epsilon values: {self.epsilon_values}")
        dp_results = self._run_dp_experiments_parallel()
        self.results['dp_experiments'] = dp_results
        
        # Analyze results
        analysis = self._analyze_privacy_utility_tradeoff()
        self.results['analysis'] = analysis
        
        # Generate comprehensive report
        report = self._generate_evaluation_report()
        self.results['report'] = report
        
        # Save results
        self._save_results()
        
        # Generate visualizations
        self._generate_visualizations()
        
        logger.info("Differential privacy evaluation completed")
        return self.results
    
    def _run_baseline_training(self) -> Dict[str, Any]:
        """Run baseline training without differential privacy."""
        # Temporarily disable DP
        original_dp_enabled = self.config['differential_privacy']['enabled']
        self.config['differential_privacy']['enabled'] = False
        
        try:
            model = build_model(self.data['X_train'].shape[1], self.config)
            model.to(self.device)
            
            # Train model
            trained_model, training_history = self._train_model(model, use_dp=False)
            
            # Evaluate
            test_metrics = self._evaluate_model(trained_model, self.data['X_test'], self.data['y_test'])
            
            return {
                'model': trained_model,
                'training_history': training_history,
                'test_metrics': test_metrics,
                'epsilon': 0.0,  # No privacy protection
                'privacy_cost': 0.0
            }
            
        finally:
            # Restore original DP setting
            self.config['differential_privacy']['enabled'] = original_dp_enabled
    
    def _run_dp_experiments_parallel(self) -> Dict[float, Dict[str, Any]]:
        """Run DP experiments in parallel for different epsilon values."""
        dp_results = {}
        
        # Use ThreadPoolExecutor for parallel execution
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            # Submit all experiments
            future_to_epsilon = {
                executor.submit(self._run_single_dp_experiment, epsilon): epsilon 
                for epsilon in self.epsilon_values
            }
            
            # Collect results
            for future in concurrent.futures.as_completed(future_to_epsilon):
                epsilon = future_to_epsilon[future]
                try:
                    result = future.result()
                    dp_results[epsilon] = result
                    logger.info(f"Completed DP experiment for ε={epsilon}")
                except Exception as e:
                    logger.error(f"DP experiment failed for ε={epsilon}: {e}")
                    dp_results[epsilon] = None
        
        return dp_results
    
    def _run_single_dp_experiment(self, epsilon: float) -> Dict[str, Any]:
        """Run a single DP experiment for given epsilon value."""
        # Create a copy of config for this experiment
        experiment_config = self.config.copy()
        experiment_config['differential_privacy'] = self.config['differential_privacy'].copy()
        experiment_config['differential_privacy']['enabled'] = True
        experiment_config['differential_privacy']['target_epsilon'] = epsilon
        
        # Adjust noise multiplier based on epsilon (simplified heuristic)
        experiment_config['differential_privacy']['noise_multiplier'] = max(0.5, 10.0 / epsilon)
        
        try:
            model = build_model(self.data['X_train'].shape[1], experiment_config)
            model.to(self.device)
            
            # Train with DP
            trained_model, training_history = self._train_model(model, use_dp=True, dp_config=experiment_config['differential_privacy'])
            
            # Evaluate
            test_metrics = self._evaluate_model(trained_model, self.data['X_test'], self.data['y_test'])
            
            # Calculate privacy cost
            baseline_auc = self.results.get('baseline', {}).get('test_metrics', {}).get('auc', 0.0)
            privacy_cost = baseline_auc - test_metrics.get('auc', 0.0)
            
            return {
                'model': trained_model,
                'training_history': training_history,
                'test_metrics': test_metrics,
                'epsilon': epsilon,
                'privacy_cost': privacy_cost,
                'noise_multiplier': experiment_config['differential_privacy']['noise_multiplier']
            }
            
        except Exception as e:
            logger.error(f"Error in DP experiment for ε={epsilon}: {e}")
            return {
                'error': str(e),
                'epsilon': epsilon,
                'test_metrics': {'auc': 0.0, 'accuracy': 0.0},
                'privacy_cost': float('inf')
            }
    
    def _train_model(self, model: torch.nn.Module, use_dp: bool = False, dp_config: Dict = None) -> Tuple[torch.nn.Module, List[Dict]]:
        """Train a model with or without differential privacy."""
        from torch.utils.data import DataLoader, TensorDataset
        import torch.optim as optim
        import torch.nn as nn
        
        # Prepare data loaders
        train_dataset = TensorDataset(
            torch.FloatTensor(self.data['X_train']), 
            torch.FloatTensor(self.data['y_train'])
        )
        val_dataset = TensorDataset(
            torch.FloatTensor(self.data['X_val']), 
            torch.FloatTensor(self.data['y_val'])
        )
        
        train_loader = DataLoader(train_dataset, batch_size=self.config['model']['batch_size'], shuffle=True)
        val_loader = DataLoader(val_dataset, batch_size=self.config['model']['batch_size'], shuffle=False)
        
        # Setup optimizer and loss
        optimizer = optim.Adam(model.parameters(), lr=self.config['model']['learning_rate'])
        criterion = nn.BCEWithLogitsLoss()
        
        # Setup DP trainer if needed
        dp_trainer = None
        if use_dp and dp_config:
            dp_trainer = DPTrainer(model, optimizer, criterion, dp_config)
        
        # Training loop
        training_history = []
        num_epochs = self.config['model'].get('epochs', 20)  # Reduced for DP evaluation
        
        for epoch in range(num_epochs):
            model.train()
            epoch_loss = 0.0
            
            for batch_X, batch_y in train_loader:
                batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                
                if use_dp and dp_trainer:
                    # Use DP trainer
                    optimizer.zero_grad()
                    outputs = model(batch_X).squeeze()
                    loss = criterion(outputs, batch_y)
                    loss.backward()
                    
                    # Apply DP noise and clipping
                    from utils.dp_utils import add_dp_noise_to_gradients
                    add_dp_noise_to_gradients(
                        model, 
                        dp_config['noise_multiplier'], 
                        dp_config['max_grad_norm']
                    )
                    
                    optimizer.step()
                else:
                    # Standard training
                    optimizer.zero_grad()
                    outputs = model(batch_X).squeeze()
                    loss = criterion(outputs, batch_y)
                    loss.backward()
                    optimizer.step()
                
                epoch_loss += loss.item()
            
            # Validation
            val_metrics = self._evaluate_model(model, self.data['X_val'], self.data['y_val'])
            
            training_history.append({
                'epoch': epoch + 1,
                'train_loss': epoch_loss / len(train_loader),
                'val_loss': val_metrics['loss'] if 'loss' in val_metrics else 0.0,
                'val_auc': val_metrics.get('auc', 0.0),
                'val_accuracy': val_metrics.get('accuracy', 0.0)
            })
            
            # Early stopping check
            if len(training_history) > 5:
                recent_aucs = [h['val_auc'] for h in training_history[-5:]]
                if max(recent_aucs) - min(recent_aucs) < 0.001:  # Converged
                    logger.info(f"Early stopping at epoch {epoch + 1}")
                    break
        
        return model, training_history
    
    def _evaluate_model(self, model: torch.nn.Module, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, float]:
        """Evaluate model on test data."""
        from torch.utils.data import DataLoader, TensorDataset
        import torch.nn as nn
        
        model.eval()
        test_dataset = TensorDataset(torch.FloatTensor(X_test), torch.FloatTensor(y_test))
        test_loader = DataLoader(test_dataset, batch_size=self.config['model']['batch_size'], shuffle=False)
        
        criterion = nn.BCEWithLogitsLoss()
        total_loss = 0.0
        all_predictions = []
        all_labels = []
        
        with torch.no_grad():
            for batch_X, batch_y in test_loader:
                batch_X, batch_y = batch_X.to(self.device), batch_y.to(self.device)
                
                outputs = model(batch_X).squeeze()
                loss = criterion(outputs, batch_y)
                total_loss += loss.item()
                
                probabilities = torch.sigmoid(outputs).cpu().numpy()
                all_predictions.extend(probabilities)
                all_labels.extend(batch_y.cpu().numpy())
        
        # Compute comprehensive metrics
        metrics = compute_classification_metrics(np.array(all_labels), np.array(all_predictions))
        metrics['loss'] = total_loss / len(test_loader)
        
        return metrics
    
    def _analyze_privacy_utility_tradeoff(self) -> Dict[str, Any]:
        """Analyze privacy-utility tradeoff across experiments."""
        analysis = {
            'epsilon_values': [],
            'auc_scores': [],
            'accuracy_scores': [],
            'privacy_costs': [],
            'utility_retention': []
        }
        
        baseline_auc = self.results['baseline']['test_metrics']['auc']
        baseline_accuracy = self.results['baseline']['test_metrics']['accuracy']
        
        for epsilon, result in self.results['dp_experiments'].items():
            if result and 'test_metrics' in result:
                analysis['epsilon_values'].append(epsilon)
                analysis['auc_scores'].append(result['test_metrics']['auc'])
                analysis['accuracy_scores'].append(result['test_metrics']['accuracy'])
                analysis['privacy_costs'].append(result['privacy_cost'])
                analysis['utility_retention'].append(result['test_metrics']['auc'] / baseline_auc)
        
        # Calculate optimal privacy-utility point
        if analysis['epsilon_values']:
            # Find epsilon that maximizes utility - privacy_penalty * epsilon
            privacy_penalty = 0.01  # Adjustable parameter
            scores = [
                auc - privacy_penalty * eps 
                for auc, eps in zip(analysis['auc_scores'], analysis['epsilon_values'])
            ]
            
            if scores:
                optimal_idx = np.argmax(scores)
                analysis['optimal_epsilon'] = analysis['epsilon_values'][optimal_idx]
                analysis['optimal_auc'] = analysis['auc_scores'][optimal_idx]
                analysis['optimal_privacy_cost'] = analysis['privacy_costs'][optimal_idx]
        
        # Calculate privacy efficiency (AUC per unit privacy cost)
        analysis['privacy_efficiency'] = []
        for auc, cost in zip(analysis['auc_scores'], analysis['privacy_costs']):
            if cost > 0:
                analysis['privacy_efficiency'].append(auc / cost)
            else:
                analysis['privacy_efficiency'].append(float('inf'))
        
        return analysis
    
    def _generate_evaluation_report(self) -> Dict[str, Any]:
        """Generate comprehensive evaluation report."""
        report = {
            'summary': {},
            'recommendations': [],
            'detailed_results': {},
            'timestamp': datetime.now().isoformat()
        }
        
        # Summary statistics
        baseline_auc = self.results['baseline']['test_metrics']['auc']
        analysis = self.results['analysis']
        
        if analysis['auc_scores']:
            report['summary'] = {
                'baseline_auc': baseline_auc,
                'min_dp_auc': min(analysis['auc_scores']),
                'max_dp_auc': max(analysis['auc_scores']),
                'avg_privacy_cost': np.mean(analysis['privacy_costs']),
                'optimal_epsilon': analysis.get('optimal_epsilon', 'N/A'),
                'utility_retention_at_optimal': analysis.get('optimal_auc', 0) / baseline_auc if baseline_auc > 0 else 0
            }
        
        # Generate recommendations
        report['recommendations'] = self._generate_recommendations(analysis, baseline_auc)
        
        # Detailed results for each epsilon
        for epsilon, result in self.results['dp_experiments'].items():
            if result and 'test_metrics' in result:
                report['detailed_results'][f'epsilon_{epsilon}'] = {
                    'epsilon': epsilon,
                    'auc': result['test_metrics']['auc'],
                    'accuracy': result['test_metrics']['accuracy'],
                    'precision': result['test_metrics']['precision'],
                    'recall': result['test_metrics']['recall'],
                    'f1': result['test_metrics']['f1'],
                    'privacy_cost': result['privacy_cost'],
                    'utility_retention': result['test_metrics']['auc'] / baseline_auc if baseline_auc > 0 else 0,
                    'noise_multiplier': result.get('noise_multiplier', 'N/A')
                }
        
        return report
    
    def _generate_recommendations(self, analysis: Dict, baseline_auc: float) -> List[str]:
        """Generate actionable recommendations based on analysis."""
        recommendations = []
        
        if not analysis['auc_scores']:
            recommendations.append("No successful DP experiments completed. Check configuration and try again.")
            return recommendations
        
        # Privacy-utility tradeoff recommendations
        max_auc = max(analysis['auc_scores'])
        min_privacy_cost = min(analysis['privacy_costs'])
        
        if max_auc / baseline_auc > 0.95:
            recommendations.append("Excellent privacy-utility tradeoff achieved. DP implementation is highly effective.")
        elif max_auc / baseline_auc > 0.90:
            recommendations.append("Good privacy-utility tradeoff. Consider fine-tuning noise parameters for better performance.")
        else:
            recommendations.append("Significant utility loss detected. Consider increasing epsilon or optimizing DP implementation.")
        
        # Optimal epsilon recommendation
        if 'optimal_epsilon' in analysis:
            optimal_eps = analysis['optimal_epsilon']
            recommendations.append(f"Recommended epsilon value: {optimal_eps:.1f} for optimal privacy-utility balance.")
        
        # Privacy level recommendations
        high_privacy_eps = [eps for eps in analysis['epsilon_values'] if eps <= 2.0]
        if high_privacy_eps:
            high_privacy_aucs = [analysis['auc_scores'][i] for i, eps in enumerate(analysis['epsilon_values']) if eps <= 2.0]
            if max(high_privacy_aucs) / baseline_auc > 0.85:
                recommendations.append("High privacy protection (ε ≤ 2.0) is feasible with acceptable utility loss.")
            else:
                recommendations.append("High privacy protection results in significant utility loss. Consider relaxing privacy requirements.")
        
        # Efficiency recommendations
        if analysis['privacy_efficiency']:
            max_efficiency_idx = np.argmax(analysis['privacy_efficiency'])
            most_efficient_eps = analysis['epsilon_values'][max_efficiency_idx]
            recommendations.append(f"Most privacy-efficient configuration: ε = {most_efficient_eps:.1f}")
        
        return recommendations
    
    def _save_results(self) -> None:
        """Save evaluation results to files."""
        os.makedirs('results', exist_ok=True)
        
        # Save complete results
        results_path = 'results/dp_evaluation_results.json'
        with open(results_path, 'w') as f:
            # Convert numpy arrays and torch tensors to lists for JSON serialization
            serializable_results = self._make_json_serializable(self.results)
            json.dump(serializable_results, f, indent=2, default=str)
        
        logger.info(f"Results saved to: {results_path}")
        
        # Save analysis as CSV
        analysis = self.results['analysis']
        if analysis['epsilon_values']:
            df = pd.DataFrame({
                'epsilon': analysis['epsilon_values'],
                'auc': analysis['auc_scores'],
                'accuracy': analysis['accuracy_scores'],
                'privacy_cost': analysis['privacy_costs'],
                'utility_retention': analysis['utility_retention']
            })
            
            csv_path = 'results/dp_privacy_utility_analysis.csv'
            df.to_csv(csv_path, index=False)
            logger.info(f"Analysis CSV saved to: {csv_path}")
        
        # Save report
        report_path = 'results/dp_evaluation_report.json'
        with open(report_path, 'w') as f:
            json.dump(self.results['report'], f, indent=2, default=str)
        
        logger.info(f"Report saved to: {report_path}")
    
    def _make_json_serializable(self, obj):
        """Convert objects to JSON-serializable format."""
        if isinstance(obj, dict):
            return {k: self._make_json_serializable(v) for k, v in obj.items() if k != 'model'}  # Skip model objects
        elif isinstance(obj, list):
            return [self._make_json_serializable(item) for item in obj]
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        elif isinstance(obj, (np.integer, np.floating)):
            return obj.item()
        elif hasattr(obj, '__dict__'):
            return str(obj)  # Convert complex objects to string
        else:
            return obj
    
    def _generate_visualizations(self) -> None:
        """Generate comprehensive visualizations."""
        analysis = self.results['analysis']
        
        if not analysis['epsilon_values']:
            logger.warning("No data available for visualization")
            return
        
        # Privacy vs Accuracy plot
        plot_privacy_vs_accuracy(
            analysis['epsilon_values'],
            analysis['accuracy_scores'],
            save_path='results/dp_privacy_vs_accuracy.png'
        )
        
        # Privacy vs AUC plot
        plt.figure(figsize=(10, 6))
        plt.plot(analysis['epsilon_values'], analysis['auc_scores'], 'bo-', linewidth=2, markersize=8)
        plt.xlabel('Privacy Level (ε)', fontsize=12)
        plt.ylabel('AUC Score', fontsize=12)
        plt.title('Privacy vs AUC Tradeoff', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        
        # Add baseline line
        baseline_auc = self.results['baseline']['test_metrics']['auc']
        plt.axhline(y=baseline_auc, color='r', linestyle='--', label=f'Baseline (no DP): {baseline_auc:.3f}')
        
        # Highlight optimal point
        if 'optimal_epsilon' in analysis:
            optimal_idx = analysis['epsilon_values'].index(analysis['optimal_epsilon'])
            plt.plot(analysis['optimal_epsilon'], analysis['auc_scores'][optimal_idx], 
                    'ro', markersize=12, label=f'Optimal: ε={analysis["optimal_epsilon"]:.1f}')
        
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/dp_privacy_vs_auc.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        # Utility retention plot
        plt.figure(figsize=(10, 6))
        plt.plot(analysis['epsilon_values'], analysis['utility_retention'], 'go-', linewidth=2, markersize=8)
        plt.xlabel('Privacy Level (ε)', fontsize=12)
        plt.ylabel('Utility Retention (%)', fontsize=12)
        plt.title('Utility Retention vs Privacy Level', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.axhline(y=1.0, color='r', linestyle='--', label='100% Utility (Baseline)')
        plt.axhline(y=0.9, color='orange', linestyle=':', label='90% Utility Threshold')
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/dp_utility_retention.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        logger.info("Visualizations saved to results/ directory")

def main():
    """Main function for DP evaluation."""
    parser = argparse.ArgumentParser(description='Evaluate differential privacy tradeoffs')
    parser.add_argument('--config', type=str, default='configs/config.yaml',
                       help='Path to configuration file')
    parser.add_argument('--epsilon-values', nargs='+', type=float,
                       help='Custom epsilon values to evaluate')
    parser.add_argument('--parallel', action='store_true',
                       help='Run experiments in parallel')
    
    args = parser.parse_args()
    
    # Load configuration
    from utils.data_utils import load_config
    config = load_config(args.config)
    
    # Create evaluation suite
    evaluator = DPEvaluationSuite(config)
    
    # Override epsilon values if provided
    if args.epsilon_values:
        evaluator.epsilon_values = args.epsilon_values
    
    # Create necessary directories
    os.makedirs('results', exist_ok=True)
    os.makedirs('logs', exist_ok=True)
    
    try:
        # Run evaluation
        results = evaluator.run_comprehensive_evaluation()
        
        # Print summary
        print("\n" + "="*60)
        print("DIFFERENTIAL PRIVACY EVALUATION SUMMARY")
        print("="*60)
        
        report = results['report']
        summary = report['summary']
        
        if summary:
            print(f"Baseline AUC (no DP): {summary['baseline_auc']:.4f}")
            print(f"Best DP AUC: {summary['max_dp_auc']:.4f}")
            print(f"Average Privacy Cost: {summary['avg_privacy_cost']:.4f}")
            print(f"Optimal Epsilon: {summary['optimal_epsilon']}")
            print(f"Utility Retention at Optimal: {summary['utility_retention_at_optimal']:.2%}")
        
        print("\nRecommendations:")
        for i, rec in enumerate(report['recommendations'], 1):
            print(f"{i}. {rec}")
        
        print(f"\nDetailed results saved to: results/")
        print("="*60)
        
    except Exception as e:
        logger.error(f"Evaluation failed: {e}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()