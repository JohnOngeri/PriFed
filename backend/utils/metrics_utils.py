"""
Comprehensive Metrics and Evaluation Utilities for Fraud Detection.
Implements advanced metrics computation, fairness analysis, and performance tracking
for federated learning systems with differential privacy.

This module provides enterprise-grade evaluation capabilities including:
- Standard classification metrics (AUC, F1, Precision, Recall)
- Fairness metrics across federated clients
- Privacy-utility tradeoff analysis
- Real-time metrics tracking and logging
- Comprehensive performance reporting
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional, Any, Union
import logging
from collections import defaultdict, OrderedDict
from datetime import datetime
import json
import os

# Scikit-learn imports
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, average_precision_score, confusion_matrix,
    classification_report, roc_curve, precision_recall_curve,
    matthews_corrcoef, cohen_kappa_score, log_loss
)
from sklearn.calibration import calibration_curve
import matplotlib.pyplot as plt
import seaborn as sns

logger = logging.getLogger(__name__)

class MetricsTracker:
    """
    Advanced metrics tracker for federated learning experiments.
    Tracks metrics across rounds, clients, and privacy settings.
    """
    
    def __init__(self, experiment_name: str = "federated_experiment"):
        """
        Initialize the metrics tracker.
        
        Args:
            experiment_name: Name of the experiment
        """
        self.experiment_name = experiment_name
        self.metrics_history = defaultdict(list)
        self.client_metrics = defaultdict(lambda: defaultdict(list))
        self.round_metrics = []
        self.privacy_metrics = []
        self.fairness_metrics = []
        
        logger.info(f"Initialized MetricsTracker for experiment: {experiment_name}")
    
    def log_round_metrics(self, round_num: int, global_metrics: Dict[str, float],
                         client_metrics: Dict[str, Dict[str, float]],
                         privacy_metrics: Optional[Dict[str, float]] = None) -> None:
        """
        Log metrics for a federated learning round.
        
        Args:
            round_num: Round number
            global_metrics: Global model metrics
            client_metrics: Per-client metrics
            privacy_metrics: Privacy-related metrics
        """
        # Store round metrics
        round_data = {
            'round': round_num,
            'timestamp': datetime.now().isoformat(),
            'global_metrics': global_metrics,
            'client_metrics': client_metrics
        }
        
        if privacy_metrics:
            round_data['privacy_metrics'] = privacy_metrics
        
        self.round_metrics.append(round_data)
        
        # Update history
        for metric_name, value in global_metrics.items():
            self.metrics_history[f'global_{metric_name}'].append(value)
        
        # Update client metrics
        for client_id, metrics in client_metrics.items():
            for metric_name, value in metrics.items():
                self.client_metrics[client_id][metric_name].append(value)
        
        # Store privacy metrics
        if privacy_metrics:
            self.privacy_metrics.append({
                'round': round_num,
                'timestamp': datetime.now().isoformat(),
                **privacy_metrics
            })
        
        logger.info(f"Round {round_num} metrics logged: "
                   f"Global AUC={global_metrics.get('auc', 0):.4f}")
    
    def compute_fairness_metrics(self, client_metrics: Dict[str, Dict[str, float]]) -> Dict[str, float]:
        """
        Compute fairness metrics across clients.
        
        Args:
            client_metrics: Per-client metrics
            
        Returns:
            Fairness metrics
        """
        fairness = {}
        
        # Extract AUC values for fairness analysis
        auc_values = [metrics.get('auc', 0) for metrics in client_metrics.values()]
        
        if len(auc_values) > 1:
            # Statistical fairness metrics
            fairness['auc_variance'] = float(np.var(auc_values))
            fairness['auc_std'] = float(np.std(auc_values))
            fairness['auc_range'] = float(max(auc_values) - min(auc_values))
            fairness['auc_coefficient_of_variation'] = float(np.std(auc_values) / np.mean(auc_values))
            
            # Demographic parity (simplified)
            fairness['max_auc_difference'] = float(max(auc_values) - min(auc_values))
            
            # Equalized odds approximation
            precision_values = [metrics.get('precision', 0) for metrics in client_metrics.values()]
            recall_values = [metrics.get('recall', 0) for metrics in client_metrics.values()]
            
            if len(precision_values) > 1 and len(recall_values) > 1:
                fairness['precision_variance'] = float(np.var(precision_values))
                fairness['recall_variance'] = float(np.var(recall_values))
                fairness['max_precision_difference'] = float(max(precision_values) - min(precision_values))
                fairness['max_recall_difference'] = float(max(recall_values) - min(recall_values))
            
            # Overall fairness score (lower is better)
            fairness['overall_fairness_score'] = float(
                fairness['auc_variance'] + 
                fairness.get('precision_variance', 0) + 
                fairness.get('recall_variance', 0)
            )
        
        # Store fairness metrics
        fairness_entry = {
            'timestamp': datetime.now().isoformat(),
            **fairness
        }
        self.fairness_metrics.append(fairness_entry)
        
        return fairness
    
    def get_summary_report(self) -> Dict[str, Any]:
        """
        Generate comprehensive summary report.
        
        Returns:
            Summary report dictionary
        """
        if not self.round_metrics:
            return {'error': 'No metrics available'}
        
        # Extract final round metrics
        final_round = self.round_metrics[-1]
        final_global = final_round['global_metrics']
        final_clients = final_round['client_metrics']
        
        # Compute trends
        trends = {}
        for metric_name, values in self.metrics_history.items():
            if len(values) > 1:
                trends[metric_name] = {
                    'initial': values[0],
                    'final': values[-1],
                    'improvement': values[-1] - values[0],
                    'best': max(values),
                    'worst': min(values)
                }
        
        # Privacy analysis
        privacy_analysis = {}
        if self.privacy_metrics:
            final_privacy = self.privacy_metrics[-1]
            privacy_analysis = {
                'final_epsilon': final_privacy.get('epsilon', 0),
                'target_epsilon': final_privacy.get('target_epsilon', 0),
                'privacy_budget_used': final_privacy.get('budget_used_percentage', 0),
                'privacy_guarantee': 'SATISFIED' if final_privacy.get('epsilon', float('inf')) <= final_privacy.get('target_epsilon', 0) else 'VIOLATED'
            }
        
        # Fairness analysis
        fairness_analysis = {}
        if self.fairness_metrics:
            final_fairness = self.fairness_metrics[-1]
            fairness_analysis = {
                'auc_variance': final_fairness.get('auc_variance', 0),
                'max_auc_difference': final_fairness.get('max_auc_difference', 0),
                'overall_fairness_score': final_fairness.get('overall_fairness_score', 0),
                'fairness_assessment': self._assess_fairness(final_fairness)
            }
        
        report = {
            'experiment_name': self.experiment_name,
            'summary': {
                'total_rounds': len(self.round_metrics),
                'num_clients': len(final_clients),
                'final_global_metrics': final_global,
                'final_client_metrics': final_clients
            },
            'trends': trends,
            'privacy_analysis': privacy_analysis,
            'fairness_analysis': fairness_analysis,
            'timestamp': datetime.now().isoformat()
        }
        
        return report
    
    def _assess_fairness(self, fairness_metrics: Dict[str, float]) -> str:
        """Assess overall fairness level."""
        auc_variance = fairness_metrics.get('auc_variance', 0)
        
        if auc_variance < 0.001:
            return "Excellent"
        elif auc_variance < 0.005:
            return "Good"
        elif auc_variance < 0.02:
            return "Fair"
        else:
            return "Poor"
    
    def save_metrics(self, filepath: str) -> None:
        """
        Save all metrics to file.
        
        Args:
            filepath: Path to save metrics
        """
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        
        metrics_data = {
            'experiment_name': self.experiment_name,
            'metrics_history': dict(self.metrics_history),
            'client_metrics': {k: dict(v) for k, v in self.client_metrics.items()},
            'round_metrics': self.round_metrics,
            'privacy_metrics': self.privacy_metrics,
            'fairness_metrics': self.fairness_metrics,
            'timestamp': datetime.now().isoformat()
        }
        
        with open(filepath, 'w') as f:
            json.dump(metrics_data, f, indent=2, default=str)
        
        logger.info(f"Metrics saved to: {filepath}")

def compute_classification_metrics(y_true: np.ndarray, y_pred_proba: np.ndarray, 
                                 threshold: float = 0.5) -> Dict[str, float]:
    """
    Compute comprehensive classification metrics.
    
    Args:
        y_true: True labels
        y_pred_proba: Predicted probabilities
        threshold: Classification threshold
        
    Returns:
        Dictionary of metrics
    """
    # Convert probabilities to binary predictions
    y_pred = (y_pred_proba >= threshold).astype(int)
    
    # Basic metrics
    metrics = {
        'accuracy': float(accuracy_score(y_true, y_pred)),
        'precision': float(precision_score(y_true, y_pred, zero_division=0)),
        'recall': float(recall_score(y_true, y_pred, zero_division=0)),
        'f1': float(f1_score(y_true, y_pred, zero_division=0)),
        'specificity': float(compute_specificity(y_true, y_pred))
    }
    
    # AUC metrics (only if both classes present)
    if len(np.unique(y_true)) > 1:
        try:
            metrics['auc'] = float(roc_auc_score(y_true, y_pred_proba))
            metrics['pr_auc'] = float(average_precision_score(y_true, y_pred_proba))
        except ValueError as e:
            logger.warning(f"AUC computation failed: {e}")
            metrics['auc'] = 0.0
            metrics['pr_auc'] = 0.0
    else:
        metrics['auc'] = 0.0
        metrics['pr_auc'] = 0.0
    
    # Additional metrics
    try:
        metrics['mcc'] = float(matthews_corrcoef(y_true, y_pred))
        metrics['kappa'] = float(cohen_kappa_score(y_true, y_pred))
        metrics['log_loss'] = float(log_loss(y_true, y_pred_proba, eps=1e-15))
    except Exception as e:
        logger.warning(f"Additional metrics computation failed: {e}")
        metrics['mcc'] = 0.0
        metrics['kappa'] = 0.0
        metrics['log_loss'] = float('inf')
    
    # Confusion matrix components
    if len(np.unique(y_true)) > 1:
        tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()
        metrics.update({
            'true_positives': int(tp),
            'true_negatives': int(tn),
            'false_positives': int(fp),
            'false_negatives': int(fn),
            'positive_rate': float(np.mean(y_pred)),
            'negative_rate': float(1 - np.mean(y_pred))
        })
    
    return metrics

def compute_specificity(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    """
    Compute specificity (true negative rate).
    
    Args:
        y_true: True labels
        y_pred: Predicted labels
        
    Returns:
        Specificity value
    """
    try:
        tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()
        return tn / (tn + fp) if (tn + fp) > 0 else 0.0
    except ValueError:
        return 0.0

def compute_fairness_metrics(client_metrics: Dict[str, Dict[str, float]]) -> Dict[str, float]:
    """
    Compute fairness metrics across clients.
    
    Args:
        client_metrics: Dictionary mapping client IDs to their metrics
        
    Returns:
        Fairness metrics
    """
    if len(client_metrics) < 2:
        return {'error': 'Need at least 2 clients for fairness analysis'}
    
    fairness = {}
    
    # Extract metric values across clients
    metric_names = ['auc', 'accuracy', 'precision', 'recall', 'f1']
    
    for metric_name in metric_names:
        values = [metrics.get(metric_name, 0) for metrics in client_metrics.values()]
        
        if len(values) > 1:
            fairness[f'{metric_name}_variance'] = float(np.var(values))
            fairness[f'{metric_name}_std'] = float(np.std(values))
            fairness[f'{metric_name}_range'] = float(max(values) - min(values))
            fairness[f'{metric_name}_cv'] = float(np.std(values) / np.mean(values)) if np.mean(values) > 0 else 0
    
    # Overall fairness score (weighted combination)
    weights = {'auc': 0.4, 'accuracy': 0.2, 'precision': 0.2, 'recall': 0.2}
    overall_score = 0.0
    
    for metric_name, weight in weights.items():
        variance_key = f'{metric_name}_variance'
        if variance_key in fairness:
            overall_score += weight * fairness[variance_key]
    
    fairness['overall_fairness_score'] = overall_score
    
    # Fairness assessment
    if overall_score < 0.001:
        fairness['fairness_level'] = 'Excellent'
    elif overall_score < 0.005:
        fairness['fairness_level'] = 'Good'
    elif overall_score < 0.02:
        fairness['fairness_level'] = 'Fair'
    else:
        fairness['fairness_level'] = 'Poor'
    
    return fairness

def compute_privacy_utility_metrics(baseline_metrics: Dict[str, float],
                                  private_metrics: Dict[str, float],
                                  epsilon: float) -> Dict[str, float]:
    """
    Compute privacy-utility tradeoff metrics.
    
    Args:
        baseline_metrics: Metrics without privacy
        private_metrics: Metrics with differential privacy
        epsilon: Privacy parameter
        
    Returns:
        Privacy-utility metrics
    """
    utility_metrics = {}
    
    # Utility loss for each metric
    for metric_name in ['auc', 'accuracy', 'precision', 'recall', 'f1']:
        baseline_val = baseline_metrics.get(metric_name, 0)
        private_val = private_metrics.get(metric_name, 0)
        
        if baseline_val > 0:
            utility_loss = baseline_val - private_val
            utility_loss_pct = (utility_loss / baseline_val) * 100
            
            utility_metrics[f'{metric_name}_utility_loss'] = float(utility_loss)
            utility_metrics[f'{metric_name}_utility_loss_pct'] = float(utility_loss_pct)
            utility_metrics[f'{metric_name}_privacy_utility_ratio'] = float(utility_loss / epsilon) if epsilon > 0 else 0
    
    # Overall utility preservation
    auc_preservation = (private_metrics.get('auc', 0) / baseline_metrics.get('auc', 1)) * 100
    utility_metrics['auc_preservation_pct'] = float(auc_preservation)
    
    # Privacy strength assessment
    if epsilon <= 1.0:
        privacy_strength = 'Very Strong'
    elif epsilon <= 3.0:
        privacy_strength = 'Strong'
    elif epsilon <= 8.0:
        privacy_strength = 'Moderate'
    elif epsilon <= 15.0:
        privacy_strength = 'Weak'
    else:
        privacy_strength = 'Very Weak'
    
    utility_metrics['privacy_strength'] = privacy_strength
    utility_metrics['epsilon'] = float(epsilon)
    
    return utility_metrics

def generate_confusion_matrix_plot(y_true: np.ndarray, y_pred: np.ndarray, 
                                 save_path: Optional[str] = None,
                                 title: str = "Confusion Matrix") -> None:
    """
    Generate and save confusion matrix plot.
    
    Args:
        y_true: True labels
        y_pred: Predicted labels
        save_path: Path to save the plot
        title: Plot title
    """
    cm = confusion_matrix(y_true, y_pred)
    
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['Safe', 'Fraud'], 
                yticklabels=['Safe', 'Fraud'])
    plt.title(title)
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"Confusion matrix saved to: {save_path}")
    
    plt.show()

def generate_roc_curve_plot(y_true: np.ndarray, y_pred_proba: np.ndarray,
                           save_path: Optional[str] = None,
                           title: str = "ROC Curve") -> None:
    """
    Generate and save ROC curve plot.
    
    Args:
        y_true: True labels
        y_pred_proba: Predicted probabilities
        save_path: Path to save the plot
        title: Plot title
    """
    if len(np.unique(y_true)) < 2:
        logger.warning("Cannot generate ROC curve: only one class present")
        return
    
    fpr, tpr, _ = roc_curve(y_true, y_pred_proba)
    auc = roc_auc_score(y_true, y_pred_proba)
    
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {auc:.4f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Random')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title(title)
    plt.legend(loc="lower right")
    plt.grid(True, alpha=0.3)
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"ROC curve saved to: {save_path}")
    
    plt.show()

def generate_precision_recall_curve_plot(y_true: np.ndarray, y_pred_proba: np.ndarray,
                                       save_path: Optional[str] = None,
                                       title: str = "Precision-Recall Curve") -> None:
    """
    Generate and save precision-recall curve plot.
    
    Args:
        y_true: True labels
        y_pred_proba: Predicted probabilities
        save_path: Path to save the plot
        title: Plot title
    """
    if len(np.unique(y_true)) < 2:
        logger.warning("Cannot generate PR curve: only one class present")
        return
    
    precision, recall, _ = precision_recall_curve(y_true, y_pred_proba)
    pr_auc = average_precision_score(y_true, y_pred_proba)
    
    plt.figure(figsize=(8, 6))
    plt.plot(recall, precision, color='darkorange', lw=2, 
             label=f'PR curve (AUC = {pr_auc:.4f})')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.title(title)
    plt.legend(loc="lower left")
    plt.grid(True, alpha=0.3)
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"PR curve saved to: {save_path}")
    
    plt.show()

def generate_calibration_plot(y_true: np.ndarray, y_pred_proba: np.ndarray,
                            save_path: Optional[str] = None,
                            title: str = "Calibration Plot") -> None:
    """
    Generate and save calibration plot.
    
    Args:
        y_true: True labels
        y_pred_proba: Predicted probabilities
        save_path: Path to save the plot
        title: Plot title
    """
    if len(np.unique(y_true)) < 2:
        logger.warning("Cannot generate calibration plot: only one class present")
        return
    
    fraction_of_positives, mean_predicted_value = calibration_curve(
        y_true, y_pred_proba, n_bins=10
    )
    
    plt.figure(figsize=(8, 6))
    plt.plot(mean_predicted_value, fraction_of_positives, "s-", 
             label="Model", color='darkorange')
    plt.plot([0, 1], [0, 1], "k:", label="Perfectly calibrated")
    plt.xlabel('Mean Predicted Probability')
    plt.ylabel('Fraction of Positives')
    plt.title(title)
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"Calibration plot saved to: {save_path}")
    
    plt.show()

def save_metrics_to_csv(metrics_dict: Dict[str, Any], filepath: str) -> None:
    """
    Save metrics dictionary to CSV file.
    
    Args:
        metrics_dict: Dictionary of metrics
        filepath: Path to save CSV file
    """
    # Flatten nested dictionaries
    flattened = {}
    
    def flatten_dict(d, parent_key='', sep='_'):
        for k, v in d.items():
            new_key = f"{parent_key}{sep}{k}" if parent_key else k
            if isinstance(v, dict):
                flattened.update(flatten_dict(v, new_key, sep=sep))
            else:
                flattened[new_key] = v
    
    flatten_dict(metrics_dict)
    
    # Convert to DataFrame and save
    df = pd.DataFrame([flattened])
    
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    df.to_csv(filepath, index=False)
    
    logger.info(f"Metrics saved to CSV: {filepath}")

def load_metrics_from_csv(filepath: str) -> Dict[str, Any]:
    """
    Load metrics from CSV file.
    
    Args:
        filepath: Path to CSV file
        
    Returns:
        Metrics dictionary
    """
    df = pd.read_csv(filepath)
    metrics = df.iloc[0].to_dict()
    
    logger.info(f"Metrics loaded from CSV: {filepath}")
    
    return metrics

# Export main functions
__all__ = [
    'MetricsTracker',
    'compute_classification_metrics',
    'compute_specificity',
    'compute_fairness_metrics',
    'compute_privacy_utility_metrics',
    'generate_confusion_matrix_plot',
    'generate_roc_curve_plot',
    'generate_precision_recall_curve_plot',
    'generate_calibration_plot',
    'save_metrics_to_csv',
    'load_metrics_from_csv'
]