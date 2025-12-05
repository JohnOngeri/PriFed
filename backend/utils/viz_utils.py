"""
Advanced Visualization Utilities for PrivFed System.
Generates comprehensive plots and visualizations for federated learning,
differential privacy, and fraud detection analysis.

This module provides enterprise-grade visualization capabilities including:
- Training progress and convergence plots
- Privacy-utility tradeoff visualizations
- Fairness analysis across clients
- Model performance comparisons
- Interactive dashboards and reports
"""

import matplotlib.pyplot as plt
import seaborn as sns
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional, Any, Union
import logging
from datetime import datetime
import os
from pathlib import Path
import json

# Set style for better-looking plots
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

logger = logging.getLogger(__name__)

class PrivFedVisualizer:
    """
    Comprehensive visualization system for PrivFed experiments.
    """
    
    def __init__(self, output_dir: str = "results/plots"):
        """
        Initialize the visualizer.
        
        Args:
            output_dir: Directory to save plots
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Configure matplotlib for high-quality plots
        plt.rcParams['figure.dpi'] = 300
        plt.rcParams['savefig.dpi'] = 300
        plt.rcParams['font.size'] = 10
        plt.rcParams['axes.titlesize'] = 12
        plt.rcParams['axes.labelsize'] = 10
        plt.rcParams['xtick.labelsize'] = 9
        plt.rcParams['ytick.labelsize'] = 9
        plt.rcParams['legend.fontsize'] = 9
        
        logger.info(f"PrivFedVisualizer initialized with output directory: {self.output_dir}")
    
    def plot_training_progress(self, round_metrics: List[Dict[str, Any]], 
                             save_name: str = "training_progress.png") -> None:
        """
        Plot federated learning training progress.
        
        Args:
            round_metrics: List of round metrics
            save_name: Name of the saved plot file
        """
        if not round_metrics:
            logger.warning("No round metrics provided for training progress plot")
            return
        
        # Extract data
        rounds = [m['round'] for m in round_metrics]
        global_metrics = [m.get('global_metrics', {}) for m in round_metrics]
        
        # Extract metric values
        metrics_to_plot = ['auc', 'accuracy', 'f1', 'precision', 'recall']
        metric_data = {}
        
        for metric in metrics_to_plot:
            values = [gm.get(metric, 0) for gm in global_metrics]
            if any(v > 0 for v in values):  # Only plot if we have valid data
                metric_data[metric] = values
        
        if not metric_data:
            logger.warning("No valid metrics found for training progress plot")
            return
        
        # Create subplots
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('Federated Learning Training Progress', fontsize=16, fontweight='bold')
        
        # Plot main metrics
        ax1 = axes[0, 0]
        if 'auc' in metric_data:
            ax1.plot(rounds, metric_data['auc'], 'o-', linewidth=2, markersize=6, label='AUC')
        if 'accuracy' in metric_data:
            ax1.plot(rounds, metric_data['accuracy'], 's-', linewidth=2, markersize=6, label='Accuracy')
        ax1.set_title('Model Performance Over Rounds')
        ax1.set_xlabel('Round')
        ax1.set_ylabel('Score')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Plot precision and recall
        ax2 = axes[0, 1]
        if 'precision' in metric_data:
            ax2.plot(rounds, metric_data['precision'], '^-', linewidth=2, markersize=6, label='Precision')
        if 'recall' in metric_data:
            ax2.plot(rounds, metric_data['recall'], 'v-', linewidth=2, markersize=6, label='Recall')
        if 'f1' in metric_data:
            ax2.plot(rounds, metric_data['f1'], 'd-', linewidth=2, markersize=6, label='F1-Score')
        ax2.set_title('Classification Metrics Over Rounds')
        ax2.set_xlabel('Round')
        ax2.set_ylabel('Score')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # Plot loss if available
        ax3 = axes[1, 0]
        loss_values = [gm.get('loss', 0) for gm in global_metrics]
        if any(v > 0 for v in loss_values):
            ax3.plot(rounds, loss_values, 'o-', linewidth=2, markersize=6, color='red')
            ax3.set_title('Training Loss Over Rounds')
            ax3.set_xlabel('Round')
            ax3.set_ylabel('Loss')
            ax3.grid(True, alpha=0.3)
        else:
            ax3.text(0.5, 0.5, 'Loss data not available', ha='center', va='center', transform=ax3.transAxes)
            ax3.set_title('Training Loss Over Rounds')
        
        # Plot convergence analysis
        ax4 = axes[1, 1]
        if 'auc' in metric_data and len(metric_data['auc']) > 1:
            # Compute improvement rate
            auc_values = metric_data['auc']
            improvements = [auc_values[i] - auc_values[i-1] for i in range(1, len(auc_values))]
            ax4.plot(rounds[1:], improvements, 'o-', linewidth=2, markersize=6, color='green')
            ax4.axhline(y=0, color='black', linestyle='--', alpha=0.5)
            ax4.set_title('AUC Improvement Rate')
            ax4.set_xlabel('Round')
            ax4.set_ylabel('AUC Improvement')
            ax4.grid(True, alpha=0.3)
        else:
            ax4.text(0.5, 0.5, 'Convergence analysis\nnot available', ha='center', va='center', transform=ax4.transAxes)
            ax4.set_title('Convergence Analysis')
        
        plt.tight_layout()
        
        # Save plot
        save_path = self.output_dir / save_name
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"Training progress plot saved to: {save_path}")
        
        plt.show()
    
    def plot_client_fairness(self, round_metrics: List[Dict[str, Any]], 
                           save_name: str = "client_fairness.png") -> None:
        """
        Plot fairness analysis across clients.
        
        Args:
            round_metrics: List of round metrics
            save_name: Name of the saved plot file
        """
        if not round_metrics:
            logger.warning("No round metrics provided for fairness plot")
            return
        
        # Extract client metrics across rounds
        all_client_data = defaultdict(list)
        rounds = []
        
        for round_data in round_metrics:
            rounds.append(round_data['round'])
            client_metrics = round_data.get('client_metrics', {})
            
            for client_id, metrics in client_metrics.items():
                all_client_data[client_id].append(metrics)
        
        if not all_client_data:
            logger.warning("No client metrics found for fairness plot")
            return
        
        # Create subplots
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('Client Fairness Analysis', fontsize=16, fontweight='bold')
        
        # Plot AUC across clients over rounds
        ax1 = axes[0, 0]
        for client_id, client_rounds in all_client_data.items():
            auc_values = [cr.get('auc', 0) for cr in client_rounds]
            ax1.plot(rounds, auc_values, 'o-', linewidth=2, markersize=4, label=client_id)
        ax1.set_title('AUC by Client Over Rounds')
        ax1.set_xlabel('Round')
        ax1.set_ylabel('AUC')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Plot final round metrics comparison
        ax2 = axes[0, 1]
        if round_metrics:
            final_round = round_metrics[-1]
            final_client_metrics = final_round.get('client_metrics', {})
            
            clients = list(final_client_metrics.keys())
            auc_values = [final_client_metrics[c].get('auc', 0) for c in clients]
            accuracy_values = [final_client_metrics[c].get('accuracy', 0) for c in clients]
            
            x = np.arange(len(clients))
            width = 0.35
            
            ax2.bar(x - width/2, auc_values, width, label='AUC', alpha=0.8)
            ax2.bar(x + width/2, accuracy_values, width, label='Accuracy', alpha=0.8)
            
            ax2.set_title('Final Round Performance by Client')
            ax2.set_xlabel('Client')
            ax2.set_ylabel('Score')
            ax2.set_xticks(x)
            ax2.set_xticklabels(clients)
            ax2.legend()
            ax2.grid(True, alpha=0.3)
        
        # Plot fairness metrics over rounds
        ax3 = axes[1, 0]
        fairness_variance = []
        fairness_range = []
        
        for round_data in round_metrics:
            client_metrics = round_data.get('client_metrics', {})
            if len(client_metrics) > 1:
                auc_values = [m.get('auc', 0) for m in client_metrics.values()]
                fairness_variance.append(np.var(auc_values))
                fairness_range.append(max(auc_values) - min(auc_values))
            else:
                fairness_variance.append(0)
                fairness_range.append(0)
        
        ax3.plot(rounds, fairness_variance, 'o-', linewidth=2, markersize=6, label='AUC Variance')
        ax3.plot(rounds, fairness_range, 's-', linewidth=2, markersize=6, label='AUC Range')
        ax3.set_title('Fairness Metrics Over Rounds')
        ax3.set_xlabel('Round')
        ax3.set_ylabel('Fairness Score')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Plot distribution of final metrics
        ax4 = axes[1, 1]
        if round_metrics and final_client_metrics:
            metrics_names = ['auc', 'accuracy', 'precision', 'recall', 'f1']
            client_names = list(final_client_metrics.keys())
            
            # Create heatmap data
            heatmap_data = []
            for metric in metrics_names:
                row = [final_client_metrics[client].get(metric, 0) for client in client_names]
                heatmap_data.append(row)
            
            im = ax4.imshow(heatmap_data, cmap='RdYlBu_r', aspect='auto')
            ax4.set_xticks(range(len(client_names)))
            ax4.set_yticks(range(len(metrics_names)))
            ax4.set_xticklabels(client_names)
            ax4.set_yticklabels(metrics_names)
            ax4.set_title('Final Metrics Heatmap')
            
            # Add text annotations
            for i in range(len(metrics_names)):
                for j in range(len(client_names)):
                    text = ax4.text(j, i, f'{heatmap_data[i][j]:.3f}',
                                   ha="center", va="center", color="black", fontsize=8)
            
            plt.colorbar(im, ax=ax4)
        
        plt.tight_layout()
        
        # Save plot
        save_path = self.output_dir / save_name
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"Client fairness plot saved to: {save_path}")
        
        plt.show()
    
    def plot_privacy_utility_tradeoff(self, privacy_metrics: List[Dict[str, Any]], 
                                    save_name: str = "privacy_utility_tradeoff.png") -> None:
        """
        Plot privacy-utility tradeoff analysis.
        
        Args:
            privacy_metrics: List of privacy metrics
            save_name: Name of the saved plot file
        """
        if not privacy_metrics:
            logger.warning("No privacy metrics provided for privacy-utility plot")
            return
        
        # Extract data
        epsilons = [pm.get('epsilon', 0) for pm in privacy_metrics]
        accuracies = [pm.get('accuracy', 0) for pm in privacy_metrics]
        aucs = [pm.get('auc', 0) for pm in privacy_metrics]
        
        # Create subplots
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('Privacy-Utility Tradeoff Analysis', fontsize=16, fontweight='bold')
        
        # Plot epsilon vs accuracy
        ax1 = axes[0, 0]
        if len(set(epsilons)) > 1:  # Only plot if we have varying epsilon values
            ax1.scatter(epsilons, accuracies, s=60, alpha=0.7, color='blue')
            ax1.plot(epsilons, accuracies, '--', alpha=0.5, color='blue')
            ax1.set_title('Privacy Budget vs Accuracy')
            ax1.set_xlabel('Epsilon (ε)')
            ax1.set_ylabel('Accuracy')
            ax1.grid(True, alpha=0.3)
        else:
            ax1.text(0.5, 0.5, 'Single epsilon value\nNo tradeoff to show', 
                    ha='center', va='center', transform=ax1.transAxes)
            ax1.set_title('Privacy Budget vs Accuracy')
        
        # Plot epsilon vs AUC
        ax2 = axes[0, 1]
        if len(set(epsilons)) > 1:
            ax2.scatter(epsilons, aucs, s=60, alpha=0.7, color='red')
            ax2.plot(epsilons, aucs, '--', alpha=0.5, color='red')
            ax2.set_title('Privacy Budget vs AUC')
            ax2.set_xlabel('Epsilon (ε)')
            ax2.set_ylabel('AUC')
            ax2.grid(True, alpha=0.3)
        else:
            ax2.text(0.5, 0.5, 'Single epsilon value\nNo tradeoff to show', 
                    ha='center', va='center', transform=ax2.transAxes)
            ax2.set_title('Privacy Budget vs AUC')
        
        # Plot privacy strength categories
        ax3 = axes[1, 0]
        privacy_categories = []
        for eps in epsilons:
            if eps <= 1.0:
                privacy_categories.append('Very Strong')
            elif eps <= 3.0:
                privacy_categories.append('Strong')
            elif eps <= 8.0:
                privacy_categories.append('Moderate')
            elif eps <= 15.0:
                privacy_categories.append('Weak')
            else:
                privacy_categories.append('Very Weak')
        
        category_counts = pd.Series(privacy_categories).value_counts()
        ax3.pie(category_counts.values, labels=category_counts.index, autopct='%1.1f%%')
        ax3.set_title('Privacy Strength Distribution')
        
        # Plot utility loss over rounds
        ax4 = axes[1, 1]
        if len(privacy_metrics) > 1:
            rounds = list(range(1, len(privacy_metrics) + 1))
            max_accuracy = max(accuracies) if accuracies else 1
            utility_losses = [max_accuracy - acc for acc in accuracies]
            
            ax4.plot(rounds, utility_losses, 'o-', linewidth=2, markersize=6, color='orange')
            ax4.set_title('Utility Loss Over Training')
            ax4.set_xlabel('Round')
            ax4.set_ylabel('Utility Loss')
            ax4.grid(True, alpha=0.3)
        else:
            ax4.text(0.5, 0.5, 'Insufficient data\nfor utility loss analysis', 
                    ha='center', va='center', transform=ax4.transAxes)
            ax4.set_title('Utility Loss Over Training')
        
        plt.tight_layout()
        
        # Save plot
        save_path = self.output_dir / save_name
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"Privacy-utility tradeoff plot saved to: {save_path}")
        
        plt.show()
    
    def plot_model_comparison(self, comparison_data: Dict[str, Dict[str, float]], 
                            save_name: str = "model_comparison.png") -> None:
        """
        Plot comparison between different models/approaches.
        
        Args:
            comparison_data: Dictionary mapping model names to their metrics
            save_name: Name of the saved plot file
        """
        if not comparison_data:
            logger.warning("No comparison data provided")
            return
        
        # Extract data
        model_names = list(comparison_data.keys())
        metrics_names = ['auc', 'accuracy', 'precision', 'recall', 'f1']
        
        # Create comparison matrix
        comparison_matrix = []
        available_metrics = []
        
        for metric in metrics_names:
            metric_values = []
            has_data = False
            for model_name in model_names:
                value = comparison_data[model_name].get(metric, 0)
                metric_values.append(value)
                if value > 0:
                    has_data = True
            
            if has_data:
                comparison_matrix.append(metric_values)
                available_metrics.append(metric)
        
        if not comparison_matrix:
            logger.warning("No valid metrics found for model comparison")
            return
        
        # Create subplots
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('Model Performance Comparison', fontsize=16, fontweight='bold')
        
        # Bar plot comparison
        ax1 = axes[0, 0]
        x = np.arange(len(model_names))
        width = 0.15
        
        colors = plt.cm.Set3(np.linspace(0, 1, len(available_metrics)))
        
        for i, (metric, values) in enumerate(zip(available_metrics, comparison_matrix)):
            ax1.bar(x + i * width, values, width, label=metric.upper(), 
                   color=colors[i], alpha=0.8)
        
        ax1.set_title('Performance Metrics Comparison')
        ax1.set_xlabel('Model')
        ax1.set_ylabel('Score')
        ax1.set_xticks(x + width * (len(available_metrics) - 1) / 2)
        ax1.set_xticklabels(model_names, rotation=45, ha='right')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Radar chart
        ax2 = axes[0, 1]
        if len(available_metrics) >= 3:
            angles = np.linspace(0, 2 * np.pi, len(available_metrics), endpoint=False)
            angles = np.concatenate((angles, [angles[0]]))  # Complete the circle
            
            for i, model_name in enumerate(model_names):
                values = [comparison_matrix[j][i] for j in range(len(available_metrics))]
                values += [values[0]]  # Complete the circle
                
                ax2.plot(angles, values, 'o-', linewidth=2, label=model_name)
                ax2.fill(angles, values, alpha=0.25)
            
            ax2.set_xticks(angles[:-1])
            ax2.set_xticklabels(available_metrics)
            ax2.set_ylim(0, 1)
            ax2.set_title('Performance Radar Chart')
            ax2.legend()
            ax2.grid(True)
        else:
            ax2.text(0.5, 0.5, 'Need at least 3 metrics\nfor radar chart', 
                    ha='center', va='center', transform=ax2.transAxes)
            ax2.set_title('Performance Radar Chart')
        
        # Heatmap
        ax3 = axes[1, 0]
        if comparison_matrix:
            im = ax3.imshow(comparison_matrix, cmap='RdYlBu_r', aspect='auto')
            ax3.set_xticks(range(len(model_names)))
            ax3.set_yticks(range(len(available_metrics)))
            ax3.set_xticklabels(model_names, rotation=45, ha='right')
            ax3.set_yticklabels(available_metrics)
            ax3.set_title('Performance Heatmap')
            
            # Add text annotations
            for i in range(len(available_metrics)):
                for j in range(len(model_names)):
                    text = ax3.text(j, i, f'{comparison_matrix[i][j]:.3f}',
                                   ha="center", va="center", color="black", fontsize=9)
            
            plt.colorbar(im, ax=ax3)
        
        # Ranking analysis
        ax4 = axes[1, 1]
        if comparison_matrix and len(model_names) > 1:
            # Calculate average rank for each model
            ranks = []
            for i, model_name in enumerate(model_names):
                model_values = [comparison_matrix[j][i] for j in range(len(available_metrics))]
                avg_score = np.mean(model_values)
                ranks.append((model_name, avg_score))
            
            ranks.sort(key=lambda x: x[1], reverse=True)
            
            ranked_names = [r[0] for r in ranks]
            ranked_scores = [r[1] for r in ranks]
            
            bars = ax4.barh(ranked_names, ranked_scores, color='skyblue', alpha=0.8)
            ax4.set_title('Overall Performance Ranking')
            ax4.set_xlabel('Average Score')
            
            # Add value labels on bars
            for i, (bar, score) in enumerate(zip(bars, ranked_scores)):
                ax4.text(score + 0.01, i, f'{score:.3f}', va='center')
        else:
            ax4.text(0.5, 0.5, 'Insufficient data\nfor ranking analysis', 
                    ha='center', va='center', transform=ax4.transAxes)
            ax4.set_title('Overall Performance Ranking')
        
        plt.tight_layout()
        
        # Save plot
        save_path = self.output_dir / save_name
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logger.info(f"Model comparison plot saved to: {save_path}")
        
        plt.show()
    
    def create_interactive_dashboard(self, round_metrics: List[Dict[str, Any]], 
                                   privacy_metrics: List[Dict[str, Any]] = None,
                                   save_name: str = "interactive_dashboard.html") -> None:
        """
        Create interactive dashboard using Plotly.
        
        Args:
            round_metrics: List of round metrics
            privacy_metrics: List of privacy metrics
            save_name: Name of the saved HTML file
        """
        if not round_metrics:
            logger.warning("No round metrics provided for interactive dashboard")
            return
        
        # Create subplots
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Training Progress', 'Client Performance', 
                          'Privacy Analysis', 'Fairness Metrics'),
            specs=[[{"secondary_y": True}, {"type": "bar"}],
                   [{"type": "scatter"}, {"type": "heatmap"}]]
        )
        
        # Extract data
        rounds = [m['round'] for m in round_metrics]
        global_metrics = [m.get('global_metrics', {}) for m in round_metrics]
        
        # Training progress
        auc_values = [gm.get('auc', 0) for gm in global_metrics]
        accuracy_values = [gm.get('accuracy', 0) for gm in global_metrics]
        
        fig.add_trace(
            go.Scatter(x=rounds, y=auc_values, mode='lines+markers', 
                      name='AUC', line=dict(color='blue')),
            row=1, col=1
        )
        
        fig.add_trace(
            go.Scatter(x=rounds, y=accuracy_values, mode='lines+markers', 
                      name='Accuracy', line=dict(color='red')),
            row=1, col=1, secondary_y=True
        )
        
        # Client performance (final round)
        if round_metrics:
            final_round = round_metrics[-1]
            final_client_metrics = final_round.get('client_metrics', {})
            
            if final_client_metrics:
                clients = list(final_client_metrics.keys())
                client_aucs = [final_client_metrics[c].get('auc', 0) for c in clients]
                
                fig.add_trace(
                    go.Bar(x=clients, y=client_aucs, name='Client AUC',
                          marker_color='lightblue'),
                    row=1, col=2
                )
        
        # Privacy analysis
        if privacy_metrics:
            privacy_rounds = [pm.get('round', i+1) for i, pm in enumerate(privacy_metrics)]
            epsilons = [pm.get('epsilon', 0) for pm in privacy_metrics]
            
            fig.add_trace(
                go.Scatter(x=privacy_rounds, y=epsilons, mode='lines+markers',
                          name='Privacy Budget (ε)', line=dict(color='green')),
                row=2, col=1
            )
        
        # Fairness heatmap
        if round_metrics and final_client_metrics:
            metrics_names = ['auc', 'accuracy', 'precision', 'recall']
            client_names = list(final_client_metrics.keys())
            
            heatmap_data = []
            for metric in metrics_names:
                row = [final_client_metrics[client].get(metric, 0) for client in client_names]
                heatmap_data.append(row)
            
            fig.add_trace(
                go.Heatmap(z=heatmap_data, x=client_names, y=metrics_names,
                          colorscale='RdYlBu', name='Fairness'),
                row=2, col=2
            )
        
        # Update layout
        fig.update_layout(
            title_text="PrivFed Interactive Dashboard",
            title_x=0.5,
            height=800,
            showlegend=True
        )
        
        # Save interactive plot
        save_path = self.output_dir / save_name
        fig.write_html(str(save_path))
        logger.info(f"Interactive dashboard saved to: {save_path}")
        
        # Show plot
        fig.show()

def generate_all_plots(output_dir: str, round_metrics: List[Dict[str, Any]], 
                      privacy_metrics: List[Dict[str, Any]], 
                      comparison_data: Dict[str, Dict[str, float]]) -> None:
    """
    Generate all visualization plots for PrivFed analysis.
    
    Args:
        output_dir: Directory to save plots
        round_metrics: List of round metrics
        privacy_metrics: List of privacy metrics
        comparison_data: Model comparison data
    """
    logger.info("Generating comprehensive visualization suite")
    
    # Initialize visualizer
    visualizer = PrivFedVisualizer(output_dir)
    
    # Generate all plots
    try:
        if round_metrics:
            visualizer.plot_training_progress(round_metrics)
            visualizer.plot_client_fairness(round_metrics)
            
            # Create interactive dashboard
            visualizer.create_interactive_dashboard(round_metrics, privacy_metrics)
        
        if privacy_metrics:
            visualizer.plot_privacy_utility_tradeoff(privacy_metrics)
        
        if comparison_data:
            visualizer.plot_model_comparison(comparison_data)
        
        logger.info("All visualizations generated successfully")
        
    except Exception as e:
        logger.error(f"Error generating visualizations: {e}")

def save_plot_data(data: Dict[str, Any], filepath: str) -> None:
    """
    Save plot data for later visualization.
    
    Args:
        data: Plot data dictionary
        filepath: Path to save data
    """
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2, default=str)
    
    logger.info(f"Plot data saved to: {filepath}")

def load_plot_data(filepath: str) -> Dict[str, Any]:
    """
    Load plot data from file.
    
    Args:
        filepath: Path to load data from
        
    Returns:
        Plot data dictionary
    """
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    logger.info(f"Plot data loaded from: {filepath}")
    
    return data

# Import required for defaultdict
from collections import defaultdict

# Export main functions
__all__ = [
    'PrivFedVisualizer',
    'generate_all_plots',
    'save_plot_data',
    'load_plot_data'
]