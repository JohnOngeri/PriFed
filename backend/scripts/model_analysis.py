#!/usr/bin/env python3
"""
Model Analysis Script for PrivFed.
Performs comprehensive analysis of trained models including feature importance,
model interpretability, and performance analysis.
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
from typing import Dict, List, Tuple, Any, Optional
from pathlib import Path
import shap
from sklearn.inspection import permutation_importance
from sklearn.metrics import confusion_matrix, classification_report

from utils.data_utils import load_config, prepare_centralized_dataset, load_preprocessing_artifacts
from utils.model_utils import load_model, get_device
from utils.metrics_utils import compute_classification_metrics
from utils.viz_utils import plot_confusion_matrix, plot_feature_importance

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelAnalyzer:
    """Comprehensive model analysis and interpretability suite."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.device = get_device(config)
        self.models = {}
        self.analysis_results = {}
        
    def load_models(self, model_paths: Dict[str, str]) -> None:
        """Load multiple models for comparison."""
        logger.info("Loading models for analysis...")
        
        for model_name, model_path in model_paths.items():
            if os.path.exists(model_path):
                try:
                    model, metadata = load_model(model_path, self.device)
                    self.models[model_name] = {
                        'model': model,
                        'metadata': metadata,
                        'path': model_path
                    }
                    logger.info(f"Loaded {model_name} from {model_path}")
                except Exception as e:
                    logger.error(f"Failed to load {model_name}: {e}")
            else:
                logger.warning(f"Model file not found: {model_path}")
    
    def run_comprehensive_analysis(self, X_test: np.ndarray, y_test: np.ndarray, 
                                 feature_names: List[str] = None) -> Dict[str, Any]:
        """Run comprehensive model analysis."""
        logger.info("Starting comprehensive model analysis...")
        
        results = {
            'timestamp': datetime.now().isoformat(),
            'models_analyzed': list(self.models.keys()),
            'performance_comparison': {},
            'feature_analysis': {},
            'interpretability': {},
            'robustness_analysis': {}
        }
        
        # Performance comparison
        logger.info("Analyzing model performance...")
        results['performance_comparison'] = self._analyze_performance(X_test, y_test)
        
        # Feature importance analysis
        if feature_names:
            logger.info("Analyzing feature importance...")
            results['feature_analysis'] = self._analyze_feature_importance(X_test, y_test, feature_names)
        
        # Model interpretability
        logger.info("Analyzing model interpretability...")
        results['interpretability'] = self._analyze_interpretability(X_test, y_test, feature_names)
        
        # Robustness analysis
        logger.info("Analyzing model robustness...")
        results['robustness_analysis'] = self._analyze_robustness(X_test, y_test)
        
        # Model comparison
        logger.info("Comparing models...")
        results['model_comparison'] = self._compare_models(X_test, y_test)
        
        self.analysis_results = results
        return results
    
    def _analyze_performance(self, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, Any]:
        """Analyze performance of all loaded models."""
        performance_results = {}
        
        for model_name, model_info in self.models.items():
            model = model_info['model']
            
            # Get predictions
            predictions, probabilities = self._get_model_predictions(model, X_test)
            
            # Compute metrics
            metrics = compute_classification_metrics(y_test, probabilities)
            
            # Additional analysis
            cm = confusion_matrix(y_test, predictions)
            
            performance_results[model_name] = {
                'metrics': metrics,
                'confusion_matrix': cm.tolist(),
                'classification_report': classification_report(y_test, predictions, output_dict=True),
                'model_info': {
                    'parameters': sum(p.numel() for p in model.parameters()),
                    'trainable_parameters': sum(p.numel() for p in model.parameters() if p.requires_grad)
                }
            }
            
            logger.info(f"{model_name} - AUC: {metrics['auc']:.4f}, Accuracy: {metrics['accuracy']:.4f}")
        
        return performance_results
    
    def _analyze_feature_importance(self, X_test: np.ndarray, y_test: np.ndarray, 
                                  feature_names: List[str]) -> Dict[str, Any]:
        """Analyze feature importance using multiple methods."""
        feature_analysis = {}
        
        for model_name, model_info in self.models.items():
            model = model_info['model']
            
            logger.info(f"Computing feature importance for {model_name}...")
            
            model_analysis = {}
            
            # Gradient-based importance
            try:
                grad_importance = self._compute_gradient_importance(model, X_test, y_test)
                model_analysis['gradient_importance'] = dict(zip(feature_names, grad_importance))
            except Exception as e:
                logger.warning(f"Gradient importance failed for {model_name}: {e}")
            
            # Permutation importance
            try:
                perm_importance = self._compute_permutation_importance(model, X_test, y_test)
                model_analysis['permutation_importance'] = dict(zip(feature_names, perm_importance))
            except Exception as e:
                logger.warning(f"Permutation importance failed for {model_name}: {e}")
            
            # SHAP values (if possible)
            try:
                shap_values = self._compute_shap_values(model, X_test[:100])  # Sample for efficiency
                model_analysis['shap_importance'] = dict(zip(feature_names, np.abs(shap_values).mean(axis=0)))
            except Exception as e:
                logger.warning(f"SHAP analysis failed for {model_name}: {e}")
            
            feature_analysis[model_name] = model_analysis
        
        return feature_analysis
    
    def _compute_gradient_importance(self, model: torch.nn.Module, X: np.ndarray, y: np.ndarray) -> np.ndarray:
        """Compute gradient-based feature importance."""
        model.eval()
        X_tensor = torch.FloatTensor(X).to(self.device)
        X_tensor.requires_grad_(True)
        
        outputs = model(X_tensor)
        outputs = torch.sigmoid(outputs).sum()
        
        gradients = torch.autograd.grad(outputs, X_tensor, create_graph=False)[0]
        importance = torch.abs(gradients).mean(dim=0).cpu().detach().numpy()
        
        return importance
    
    def _compute_permutation_importance(self, model: torch.nn.Module, X: np.ndarray, y: np.ndarray) -> np.ndarray:
        """Compute permutation-based feature importance."""
        # Create a wrapper for sklearn compatibility
        def model_predict(X_input):
            model.eval()
            with torch.no_grad():
                X_tensor = torch.FloatTensor(X_input).to(self.device)
                outputs = model(X_tensor)
                return torch.sigmoid(outputs).cpu().numpy().flatten()
        
        # Use a subset for efficiency
        sample_size = min(1000, len(X))
        indices = np.random.choice(len(X), sample_size, replace=False)
        X_sample, y_sample = X[indices], y[indices]
        
        # Compute baseline score
        baseline_predictions = model_predict(X_sample)
        baseline_score = compute_classification_metrics(y_sample, baseline_predictions)['auc']
        
        # Compute importance by permuting each feature
        importance_scores = []
        
        for feature_idx in range(X.shape[1]):
            X_permuted = X_sample.copy()
            np.random.shuffle(X_permuted[:, feature_idx])
            
            permuted_predictions = model_predict(X_permuted)
            permuted_score = compute_classification_metrics(y_sample, permuted_predictions)['auc']
            
            importance = baseline_score - permuted_score
            importance_scores.append(max(0, importance))  # Only positive importance
        
        return np.array(importance_scores)
    
    def _compute_shap_values(self, model: torch.nn.Module, X: np.ndarray) -> np.ndarray:
        """Compute SHAP values for model interpretability."""
        # Create a wrapper for SHAP
        def model_predict(X_input):
            model.eval()
            with torch.no_grad():
                if isinstance(X_input, np.ndarray):
                    X_tensor = torch.FloatTensor(X_input).to(self.device)
                else:
                    X_tensor = X_input.to(self.device)
                outputs = model(X_tensor)
                return torch.sigmoid(outputs).cpu().numpy()
        
        # Use a background dataset (sample of training data)
        background_size = min(100, len(X))
        background_indices = np.random.choice(len(X), background_size, replace=False)
        background = X[background_indices]
        
        # Create SHAP explainer
        explainer = shap.KernelExplainer(model_predict, background)
        
        # Compute SHAP values for a sample
        sample_size = min(50, len(X))
        sample_indices = np.random.choice(len(X), sample_size, replace=False)
        shap_values = explainer.shap_values(X[sample_indices])
        
        return shap_values
    
    def _analyze_interpretability(self, X_test: np.ndarray, y_test: np.ndarray, 
                                feature_names: List[str] = None) -> Dict[str, Any]:
        """Analyze model interpretability and explainability."""
        interpretability_results = {}
        
        for model_name, model_info in self.models.items():
            model = model_info['model']
            
            model_interpretability = {}
            
            # Model complexity metrics
            total_params = sum(p.numel() for p in model.parameters())
            trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
            
            model_interpretability['complexity'] = {
                'total_parameters': total_params,
                'trainable_parameters': trainable_params,
                'model_depth': len(list(model.modules())),
                'complexity_score': total_params / 1000  # Simplified complexity score
            }
            
            # Decision boundary analysis
            try:
                boundary_analysis = self._analyze_decision_boundary(model, X_test, y_test)
                model_interpretability['decision_boundary'] = boundary_analysis
            except Exception as e:
                logger.warning(f"Decision boundary analysis failed for {model_name}: {e}")
            
            # Prediction confidence analysis
            predictions, probabilities = self._get_model_predictions(model, X_test)
            confidence_analysis = self._analyze_prediction_confidence(probabilities, y_test)
            model_interpretability['confidence_analysis'] = confidence_analysis
            
            interpretability_results[model_name] = model_interpretability
        
        return interpretability_results
    
    def _analyze_decision_boundary(self, model: torch.nn.Module, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Analyze model decision boundary characteristics."""
        predictions, probabilities = self._get_model_predictions(model, X)
        
        # Analyze prediction distribution
        prob_bins = np.histogram(probabilities, bins=20, range=(0, 1))
        
        # Find decision threshold that maximizes F1 score
        thresholds = np.linspace(0.1, 0.9, 50)
        f1_scores = []
        
        for threshold in thresholds:
            pred_at_threshold = (probabilities >= threshold).astype(int)
            metrics = compute_classification_metrics(y, probabilities, threshold=threshold)
            f1_scores.append(metrics['f1'])
        
        optimal_threshold_idx = np.argmax(f1_scores)
        optimal_threshold = thresholds[optimal_threshold_idx]
        
        return {
            'probability_distribution': {
                'bins': prob_bins[1].tolist(),
                'counts': prob_bins[0].tolist()
            },
            'optimal_threshold': float(optimal_threshold),
            'max_f1_score': float(f1_scores[optimal_threshold_idx]),
            'threshold_sensitivity': float(np.std(f1_scores))
        }
    
    def _analyze_prediction_confidence(self, probabilities: np.ndarray, y_true: np.ndarray) -> Dict[str, Any]:
        """Analyze prediction confidence and calibration."""
        # Confidence bins
        confidence_bins = np.linspace(0, 1, 11)
        bin_accuracies = []
        bin_confidences = []
        bin_counts = []
        
        for i in range(len(confidence_bins) - 1):
            bin_mask = (probabilities >= confidence_bins[i]) & (probabilities < confidence_bins[i + 1])
            if np.sum(bin_mask) > 0:
                bin_accuracy = np.mean(y_true[bin_mask] == (probabilities[bin_mask] > 0.5))
                bin_confidence = np.mean(probabilities[bin_mask])
                bin_count = np.sum(bin_mask)
            else:
                bin_accuracy = 0
                bin_confidence = 0
                bin_count = 0
            
            bin_accuracies.append(bin_accuracy)
            bin_confidences.append(bin_confidence)
            bin_counts.append(bin_count)
        
        # Calibration error (Expected Calibration Error)
        ece = 0
        total_samples = len(probabilities)
        for acc, conf, count in zip(bin_accuracies, bin_confidences, bin_counts):
            if count > 0:
                ece += (count / total_samples) * abs(acc - conf)
        
        return {
            'expected_calibration_error': float(ece),
            'confidence_distribution': {
                'bin_boundaries': confidence_bins.tolist(),
                'bin_accuracies': bin_accuracies,
                'bin_confidences': bin_confidences,
                'bin_counts': bin_counts
            },
            'overconfidence_rate': float(np.mean(probabilities > 0.8)),
            'underconfidence_rate': float(np.mean(probabilities < 0.2))
        }
    
    def _analyze_robustness(self, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, Any]:
        """Analyze model robustness to input perturbations."""
        robustness_results = {}
        
        for model_name, model_info in self.models.items():
            model = model_info['model']
            
            logger.info(f"Analyzing robustness for {model_name}...")
            
            # Noise robustness
            noise_robustness = self._test_noise_robustness(model, X_test, y_test)
            
            # Feature dropout robustness
            dropout_robustness = self._test_feature_dropout_robustness(model, X_test, y_test)
            
            robustness_results[model_name] = {
                'noise_robustness': noise_robustness,
                'feature_dropout_robustness': dropout_robustness
            }
        
        return robustness_results
    
    def _test_noise_robustness(self, model: torch.nn.Module, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Test model robustness to input noise."""
        baseline_predictions, baseline_probs = self._get_model_predictions(model, X)
        baseline_auc = compute_classification_metrics(y, baseline_probs)['auc']
        
        noise_levels = [0.01, 0.05, 0.1, 0.2, 0.3]
        robustness_scores = []
        
        for noise_level in noise_levels:
            # Add Gaussian noise
            X_noisy = X + np.random.normal(0, noise_level, X.shape)
            
            noisy_predictions, noisy_probs = self._get_model_predictions(model, X_noisy)
            noisy_auc = compute_classification_metrics(y, noisy_probs)['auc']
            
            robustness_score = noisy_auc / baseline_auc if baseline_auc > 0 else 0
            robustness_scores.append(robustness_score)
        
        return {
            'noise_levels': noise_levels,
            'robustness_scores': robustness_scores,
            'avg_robustness': float(np.mean(robustness_scores)),
            'robustness_decline_rate': float(np.polyfit(noise_levels, robustness_scores, 1)[0])
        }
    
    def _test_feature_dropout_robustness(self, model: torch.nn.Module, X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
        """Test model robustness to feature dropout."""
        baseline_predictions, baseline_probs = self._get_model_predictions(model, X)
        baseline_auc = compute_classification_metrics(y, baseline_probs)['auc']
        
        dropout_rates = [0.1, 0.2, 0.3, 0.4, 0.5]
        robustness_scores = []
        
        for dropout_rate in dropout_rates:
            # Randomly drop features
            X_dropped = X.copy()
            num_features_to_drop = int(dropout_rate * X.shape[1])
            
            for i in range(len(X_dropped)):
                features_to_drop = np.random.choice(X.shape[1], num_features_to_drop, replace=False)
                X_dropped[i, features_to_drop] = 0
            
            dropped_predictions, dropped_probs = self._get_model_predictions(model, X_dropped)
            dropped_auc = compute_classification_metrics(y, dropped_probs)['auc']
            
            robustness_score = dropped_auc / baseline_auc if baseline_auc > 0 else 0
            robustness_scores.append(robustness_score)
        
        return {
            'dropout_rates': dropout_rates,
            'robustness_scores': robustness_scores,
            'avg_robustness': float(np.mean(robustness_scores)),
            'robustness_decline_rate': float(np.polyfit(dropout_rates, robustness_scores, 1)[0])
        }
    
    def _compare_models(self, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, Any]:
        """Compare multiple models across various dimensions."""
        if len(self.models) < 2:
            return {'error': 'Need at least 2 models for comparison'}
        
        comparison_results = {
            'performance_ranking': {},
            'complexity_comparison': {},
            'agreement_analysis': {},
            'ensemble_potential': {}
        }
        
        # Performance ranking
        model_aucs = {}
        for model_name, model_info in self.models.items():
            predictions, probabilities = self._get_model_predictions(model_info['model'], X_test)
            auc = compute_classification_metrics(y_test, probabilities)['auc']
            model_aucs[model_name] = auc
        
        sorted_models = sorted(model_aucs.items(), key=lambda x: x[1], reverse=True)
        comparison_results['performance_ranking'] = {
            'ranking': [model for model, _ in sorted_models],
            'scores': dict(sorted_models)
        }
        
        # Model agreement analysis
        all_predictions = {}
        for model_name, model_info in self.models.items():
            predictions, _ = self._get_model_predictions(model_info['model'], X_test)
            all_predictions[model_name] = predictions
        
        # Calculate pairwise agreement
        model_names = list(all_predictions.keys())
        agreement_matrix = np.zeros((len(model_names), len(model_names)))
        
        for i, model1 in enumerate(model_names):
            for j, model2 in enumerate(model_names):
                if i != j:
                    agreement = np.mean(all_predictions[model1] == all_predictions[model2])
                    agreement_matrix[i, j] = agreement
                else:
                    agreement_matrix[i, j] = 1.0
        
        comparison_results['agreement_analysis'] = {
            'model_names': model_names,
            'agreement_matrix': agreement_matrix.tolist(),
            'avg_agreement': float(np.mean(agreement_matrix[agreement_matrix != 1.0]))
        }
        
        return comparison_results
    
    def _get_model_predictions(self, model: torch.nn.Module, X: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """Get model predictions and probabilities."""
        model.eval()
        
        with torch.no_grad():
            X_tensor = torch.FloatTensor(X).to(self.device)
            outputs = model(X_tensor)
            probabilities = torch.sigmoid(outputs).cpu().numpy().flatten()
            predictions = (probabilities > 0.5).astype(int)
        
        return predictions, probabilities
    
    def generate_report(self, output_path: str = 'results/model_analysis_report.json') -> None:
        """Generate comprehensive analysis report."""
        if not self.analysis_results:
            logger.error("No analysis results available. Run analysis first.")
            return
        
        # Create output directory
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Save detailed results
        with open(output_path, 'w') as f:
            json.dump(self.analysis_results, f, indent=2, default=str)
        
        logger.info(f"Analysis report saved to: {output_path}")
        
        # Generate summary report
        summary_path = output_path.replace('.json', '_summary.txt')
        self._generate_summary_report(summary_path)
    
    def _generate_summary_report(self, output_path: str) -> None:
        """Generate human-readable summary report."""
        with open(output_path, 'w') as f:
            f.write("MODEL ANALYSIS SUMMARY REPORT\n")
            f.write("=" * 50 + "\n\n")
            
            # Performance summary
            f.write("PERFORMANCE COMPARISON\n")
            f.write("-" * 25 + "\n")
            
            perf_results = self.analysis_results.get('performance_comparison', {})
            for model_name, results in perf_results.items():
                metrics = results['metrics']
                f.write(f"{model_name}:\n")
                f.write(f"  AUC: {metrics['auc']:.4f}\n")
                f.write(f"  Accuracy: {metrics['accuracy']:.4f}\n")
                f.write(f"  F1 Score: {metrics['f1']:.4f}\n")
                f.write(f"  Parameters: {results['model_info']['parameters']:,}\n\n")
            
            # Feature importance summary
            f.write("FEATURE IMPORTANCE INSIGHTS\n")
            f.write("-" * 30 + "\n")
            
            feature_results = self.analysis_results.get('feature_analysis', {})
            for model_name, analysis in feature_results.items():
                f.write(f"{model_name}:\n")
                
                if 'gradient_importance' in analysis:
                    top_features = sorted(analysis['gradient_importance'].items(), 
                                        key=lambda x: x[1], reverse=True)[:5]
                    f.write("  Top 5 Important Features (Gradient-based):\n")
                    for feature, importance in top_features:
                        f.write(f"    {feature}: {importance:.4f}\n")
                f.write("\n")
            
            # Model comparison summary
            f.write("MODEL COMPARISON\n")
            f.write("-" * 20 + "\n")
            
            comparison = self.analysis_results.get('model_comparison', {})
            if 'performance_ranking' in comparison:
                ranking = comparison['performance_ranking']
                f.write("Performance Ranking:\n")
                for i, model in enumerate(ranking['ranking'], 1):
                    score = ranking['scores'][model]
                    f.write(f"  {i}. {model}: {score:.4f}\n")
            
            f.write(f"\nReport generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        logger.info(f"Summary report saved to: {output_path}")

def main():
    """Main function for model analysis."""
    parser = argparse.ArgumentParser(description='Analyze trained models')
    parser.add_argument('--config', type=str, default='configs/config.yaml',
                       help='Path to configuration file')
    parser.add_argument('--models', nargs='+', required=True,
                       help='Paths to model files to analyze')
    parser.add_argument('--model-names', nargs='+',
                       help='Names for the models (optional)')
    parser.add_argument('--output', type=str, default='results/model_analysis_report.json',
                       help='Output path for analysis report')
    
    args = parser.parse_args()
    
    # Load configuration
    from utils.data_utils import load_config
    config = load_config(args.config)
    
    # Prepare model paths
    model_paths = {}
    model_names = args.model_names if args.model_names else [f"model_{i+1}" for i in range(len(args.models))]
    
    for name, path in zip(model_names, args.models):
        model_paths[name] = path
    
    # Create analyzer
    analyzer = ModelAnalyzer(config)
    
    # Load models
    analyzer.load_models(model_paths)
    
    if not analyzer.models:
        logger.error("No models loaded successfully")
        return
    
    # Prepare test data
    logger.info("Preparing test data...")
    _, _, X_test, _, _, y_test, preprocessing_artifacts = prepare_centralized_dataset(config)
    
    # Get feature names if available
    feature_names = preprocessing_artifacts.get('feature_names', None)
    if not feature_names:
        feature_names = [f'feature_{i}' for i in range(X_test.shape[1])]
    
    # Run analysis
    try:
        results = analyzer.run_comprehensive_analysis(X_test, y_test, feature_names)
        
        # Generate report
        analyzer.generate_report(args.output)
        
        print(f"\nModel analysis completed successfully!")
        print(f"Results saved to: {args.output}")
        print(f"Models analyzed: {list(analyzer.models.keys())}")
        
    except Exception as e:
        logger.error(f"Analysis failed: {e}", exc_info=True)

if __name__ == "__main__":
    main()