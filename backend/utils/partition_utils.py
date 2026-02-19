"""
Advanced Non-IID Data Partitioning Utilities for Federated Learning.
Implements multiple sophisticated partitioning strategies to simulate realistic
cross-bank data heterogeneity in fraud detection scenarios.

This module provides enterprise-grade partitioning capabilities including:
- Time-based partitioning (primary strategy)
- Geographic-based partitioning using proxy features
- Customer segment-based partitioning
- Comprehensive validation and quality assessment
- Detailed logging and statistics tracking
"""

import numpy as np
import pandas as pd
from typing import Dict, Tuple, List, Optional, Any, Union
import logging
from datetime import datetime, timedelta
from collections import Counter, defaultdict
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import warnings

warnings.filterwarnings('ignore')
logger = logging.getLogger(__name__)

class NonIIDPartitioner:
    """
    Advanced non-IID data partitioner with multiple strategies and comprehensive validation.
    """
    
    def __init__(self, random_state: int = 42):
        """
        Initialize the partitioner.
        
        Args:
            random_state: Random seed for reproducibility
        """
        self.random_state = random_state
        np.random.seed(random_state)
        self.partition_stats = {}
        
    def create_noniid_splits(self, X: np.ndarray, y: np.ndarray, 
                           strategy: str = "time_based", num_banks: int = 3,
                           **kwargs) -> Dict[str, Tuple[np.ndarray, np.ndarray]]:
        """
        Create non-IID splits using specified strategy.
        
        Args:
            X: Feature matrix
            y: Target labels
            strategy: Partitioning strategy ('time_based', 'geographic', 'customer_segment')
            num_banks: Number of banks to create
            **kwargs: Additional strategy-specific parameters
            
        Returns:
            Dictionary mapping bank names to (X, y) tuples
        """
        logger.info(f"Creating non-IID splits using {strategy} strategy for {num_banks} banks")
        
        if strategy == "time_based":
            return self._time_based_partitioning(X, y, num_banks, **kwargs)
        elif strategy == "geographic":
            return self._geographic_partitioning(X, y, num_banks, **kwargs)
        elif strategy == "customer_segment":
            return self._customer_segment_partitioning(X, y, num_banks, **kwargs)
        else:
            raise ValueError(f"Unknown partitioning strategy: {strategy}")
    
    def _time_based_partitioning(self, X: np.ndarray, y: np.ndarray, 
                                num_banks: int, **kwargs) -> Dict[str, Tuple[np.ndarray, np.ndarray]]:
        """
        Time-based partitioning strategy (primary strategy).
        
        Simulates banks operating in different time periods or time zones,
        creating natural temporal heterogeneity in fraud patterns.
        
        Args:
            X: Feature matrix
            y: Target labels
            num_banks: Number of banks
            
        Returns:
            Dictionary mapping bank names to data splits
        """
        logger.info("Applying time-based partitioning strategy")
        
        # Assume TransactionDT is the first feature (or find it)
        # For IEEE-CIS dataset, TransactionDT represents time
        transaction_dt_idx = 0  # Assuming first feature is TransactionDT
        
        if X.shape[1] > transaction_dt_idx:
            time_values = X[:, transaction_dt_idx]
        else:
            # If no time feature, create synthetic time ordering
            logger.warning("No time feature found, creating synthetic time ordering")
            time_values = np.arange(len(X))
        
        # Sort by time
        time_sorted_indices = np.argsort(time_values)
        X_sorted = X[time_sorted_indices]
        y_sorted = y[time_sorted_indices]
        
        # Create time-based splits with overlap for realism
        total_samples = len(X_sorted)
        overlap_ratio = kwargs.get('overlap_ratio', 0.1)  # 10% overlap between banks
        
        bank_splits = {}
        bank_names = [f"bank_{chr(65+i)}" for i in range(num_banks)]  # bank_A, bank_B, bank_C
        
        for i, bank_name in enumerate(bank_names):
            # Calculate start and end indices for this bank
            start_ratio = i / num_banks
            end_ratio = (i + 1) / num_banks + overlap_ratio
            
            start_idx = int(start_ratio * total_samples)
            end_idx = min(int(end_ratio * total_samples), total_samples)
            
            # Extract bank data
            X_bank = X_sorted[start_idx:end_idx]
            y_bank = y_sorted[start_idx:end_idx]
            
            # Ensure minimum samples and class balance
            X_bank, y_bank = self._ensure_minimum_samples_and_balance(
                X_bank, y_bank, min_samples=kwargs.get('min_samples', 1000)
            )
            
            bank_splits[bank_name] = (X_bank, y_bank)
            
            # Log statistics
            fraud_rate = y_bank.mean()
            time_range = (time_values[time_sorted_indices[start_idx]], 
                         time_values[time_sorted_indices[min(end_idx-1, total_samples-1)]])
            
            logger.info(f"{bank_name}: {len(X_bank)} samples, fraud rate: {fraud_rate:.4f}, "
                       f"time range: {time_range[0]:.0f} - {time_range[1]:.0f}")
        
        # Store partition statistics
        self._compute_partition_statistics(bank_splits, "time_based")
        
        return bank_splits
    
    def _geographic_partitioning(self, X: np.ndarray, y: np.ndarray, 
                               num_banks: int, **kwargs) -> Dict[str, Tuple[np.ndarray, np.ndarray]]:
        """
        Geographic-based partitioning using proxy geographic features.
        
        Uses features like IP addresses, device info, and location proxies
        to simulate banks serving different geographic regions.
        
        Args:
            X: Feature matrix
            y: Target labels
            num_banks: Number of banks
            
        Returns:
            Dictionary mapping bank names to data splits
        """
        logger.info("Applying geographic-based partitioning strategy")
        
        # Identify potential geographic proxy features
        # For IEEE-CIS, these might be dist1, dist2, or device-related features
        geographic_features = []
        
        # Assume certain feature indices represent geographic proxies
        # This would need to be adapted based on actual feature names
        potential_geo_indices = list(range(min(10, X.shape[1])))  # First 10 features as proxy
        
        if len(potential_geo_indices) > 0:
            X_geo = X[:, potential_geo_indices]
            
            # Handle missing values
            X_geo = np.nan_to_num(X_geo, nan=0.0)
            
            # Standardize features for clustering
            scaler = StandardScaler()
            X_geo_scaled = scaler.fit_transform(X_geo)
            
            # Use K-means clustering to create geographic regions
            kmeans = KMeans(n_clusters=num_banks, random_state=self.random_state, n_init=10)
            cluster_labels = kmeans.fit_predict(X_geo_scaled)
            
        else:
            # Fallback: random assignment with geographic-like patterns
            logger.warning("No geographic features identified, using random assignment")
            cluster_labels = np.random.choice(num_banks, size=len(X))
        
        # Create bank splits based on clusters
        bank_splits = {}
        bank_names = [f"bank_{chr(65+i)}" for i in range(num_banks)]
        
        for i, bank_name in enumerate(bank_names):
            mask = cluster_labels == i
            X_bank = X[mask]
            y_bank = y[mask]
            
            # Ensure minimum samples and class balance
            X_bank, y_bank = self._ensure_minimum_samples_and_balance(
                X_bank, y_bank, min_samples=kwargs.get('min_samples', 1000)
            )
            
            bank_splits[bank_name] = (X_bank, y_bank)
            
            # Log statistics
            fraud_rate = y_bank.mean()
            logger.info(f"{bank_name}: {len(X_bank)} samples, fraud rate: {fraud_rate:.4f}")
        
        # Store partition statistics
        self._compute_partition_statistics(bank_splits, "geographic")
        
        return bank_splits
    
    def _customer_segment_partitioning(self, X: np.ndarray, y: np.ndarray, 
                                     num_banks: int, **kwargs) -> Dict[str, Tuple[np.ndarray, np.ndarray]]:
        """
        Customer segment-based partitioning.
        
        Partitions data based on customer characteristics like transaction amounts,
        merchant categories, and behavioral patterns.
        
        Args:
            X: Feature matrix
            y: Target labels
            num_banks: Number of banks
            
        Returns:
            Dictionary mapping bank names to data splits
        """
        logger.info("Applying customer segment-based partitioning strategy")
        
        # Identify transaction amount and behavioral features
        # Assume TransactionAmt is one of the early features
        amount_idx = 1 if X.shape[1] > 1 else 0
        
        # Create customer segments based on transaction amounts and patterns
        transaction_amounts = X[:, amount_idx]
        
        # Define segments based on transaction amount percentiles
        percentiles = np.linspace(0, 100, num_banks + 1)
        amount_thresholds = np.percentile(transaction_amounts, percentiles)
        
        bank_splits = {}
        bank_names = [f"bank_{chr(65+i)}" for i in range(num_banks)]
        
        for i, bank_name in enumerate(bank_names):
            # Create mask for this segment
            if i == 0:
                mask = transaction_amounts <= amount_thresholds[i + 1]
            elif i == num_banks - 1:
                mask = transaction_amounts > amount_thresholds[i]
            else:
                mask = (transaction_amounts > amount_thresholds[i]) & \
                       (transaction_amounts <= amount_thresholds[i + 1])
            
            X_bank = X[mask]
            y_bank = y[mask]
            
            # Ensure minimum samples and class balance
            X_bank, y_bank = self._ensure_minimum_samples_and_balance(
                X_bank, y_bank, min_samples=kwargs.get('min_samples', 1000)
            )
            
            bank_splits[bank_name] = (X_bank, y_bank)
            
            # Log statistics
            fraud_rate = y_bank.mean()
            amount_range = (transaction_amounts[mask].min(), transaction_amounts[mask].max())
            logger.info(f"{bank_name}: {len(X_bank)} samples, fraud rate: {fraud_rate:.4f}, "
                       f"amount range: ${amount_range[0]:.2f} - ${amount_range[1]:.2f}")
        
        # Store partition statistics
        self._compute_partition_statistics(bank_splits, "customer_segment")
        
        return bank_splits
    
    def _ensure_minimum_samples_and_balance(self, X: np.ndarray, y: np.ndarray, 
                                          min_samples: int = 1000) -> Tuple[np.ndarray, np.ndarray]:
        """
        Ensure minimum number of samples and reasonable class balance.
        
        Args:
            X: Feature matrix
            y: Target labels
            min_samples: Minimum number of samples required
            
        Returns:
            Adjusted (X, y) with minimum samples and balance
        """
        if len(X) < min_samples:
            # If not enough samples, duplicate some samples
            shortage = min_samples - len(X)
            duplicate_indices = np.random.choice(len(X), size=shortage, replace=True)
            
            X = np.vstack([X, X[duplicate_indices]])
            y = np.hstack([y, y[duplicate_indices]])
            
            logger.warning(f"Duplicated {shortage} samples to meet minimum requirement")
        
        # Ensure both classes are present
        unique_classes = np.unique(y)
        if len(unique_classes) < 2:
            # Add a few samples of the missing class
            missing_class = 1 - unique_classes[0]
            num_to_add = max(10, int(0.01 * len(y)))  # At least 10 or 1% of data
            
            # Create synthetic samples by duplicating existing samples and flipping labels
            indices_to_flip = np.random.choice(len(y), size=num_to_add, replace=True)
            
            X_synthetic = X[indices_to_flip].copy()
            y_synthetic = np.full(num_to_add, missing_class)
            
            X = np.vstack([X, X_synthetic])
            y = np.hstack([y, y_synthetic])
            
            logger.warning(f"Added {num_to_add} synthetic samples for class {missing_class}")
        
        return X, y
    
    def _compute_partition_statistics(self, bank_splits: Dict[str, Tuple[np.ndarray, np.ndarray]], 
                                    strategy: str) -> None:
        """
        Compute comprehensive statistics for the partition.
        
        Args:
            bank_splits: Dictionary of bank data splits
            strategy: Partitioning strategy used
        """
        stats = {
            'strategy': strategy,
            'num_banks': len(bank_splits),
            'total_samples': sum(len(X) for X, _ in bank_splits.values()),
            'banks': {}
        }
        
        fraud_rates = []
        sample_counts = []
        
        for bank_name, (X, y) in bank_splits.items():
            bank_stats = {
                'samples': len(X),
                'features': X.shape[1],
                'fraud_count': int(y.sum()),
                'fraud_rate': float(y.mean()),
                'class_distribution': dict(zip(*np.unique(y, return_counts=True)))
            }
            
            stats['banks'][bank_name] = bank_stats
            fraud_rates.append(bank_stats['fraud_rate'])
            sample_counts.append(bank_stats['samples'])
        
        # Compute heterogeneity metrics
        stats['heterogeneity'] = {
            'fraud_rate_variance': float(np.var(fraud_rates)),
            'fraud_rate_std': float(np.std(fraud_rates)),
            'sample_count_variance': float(np.var(sample_counts)),
            'sample_count_std': float(np.std(sample_counts)),
            'fraud_rate_range': (float(min(fraud_rates)), float(max(fraud_rates))),
            'sample_count_range': (min(sample_counts), max(sample_counts))
        }
        
        # Compute Jensen-Shannon divergence for distribution comparison
        stats['heterogeneity']['js_divergence'] = self._compute_js_divergence(bank_splits)
        
        self.partition_stats = stats
        
        # Log summary statistics
        logger.info("Partition Statistics Summary:")
        logger.info(f"  Strategy: {strategy}")
        logger.info(f"  Total samples: {stats['total_samples']:,}")
        logger.info(f"  Fraud rate variance: {stats['heterogeneity']['fraud_rate_variance']:.6f}")
        logger.info(f"  Fraud rate range: {stats['heterogeneity']['fraud_rate_range']}")
        logger.info(f"  JS divergence: {stats['heterogeneity']['js_divergence']:.4f}")
    
    def _compute_js_divergence(self, bank_splits: Dict[str, Tuple[np.ndarray, np.ndarray]]) -> float:
        """
        Compute Jensen-Shannon divergence between bank distributions.
        
        Args:
            bank_splits: Dictionary of bank data splits
            
        Returns:
            Average JS divergence between all bank pairs
        """
        from scipy.spatial.distance import jensenshannon
        
        # Get class distributions for each bank
        distributions = []
        for _, (_, y) in bank_splits.items():
            class_counts = np.bincount(y.astype(int), minlength=2)
            distribution = class_counts / class_counts.sum()
            distributions.append(distribution)
        
        # Compute pairwise JS divergences
        js_divergences = []
        for i in range(len(distributions)):
            for j in range(i + 1, len(distributions)):
                js_div = jensenshannon(distributions[i], distributions[j])
                js_divergences.append(js_div)
        
        return float(np.mean(js_divergences)) if js_divergences else 0.0
    
    def visualize_partition_statistics(self, save_path: Optional[str] = None) -> None:
        """
        Create visualizations of partition statistics.
        
        Args:
            save_path: Optional path to save the visualization
        """
        if not self.partition_stats:
            logger.warning("No partition statistics available for visualization")
            return
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle(f'Partition Statistics - {self.partition_stats["strategy"].title()} Strategy', 
                     fontsize=16, fontweight='bold')
        
        # Extract data for visualization
        bank_names = list(self.partition_stats['banks'].keys())
        fraud_rates = [self.partition_stats['banks'][bank]['fraud_rate'] for bank in bank_names]
        sample_counts = [self.partition_stats['banks'][bank]['samples'] for bank in bank_names]
        fraud_counts = [self.partition_stats['banks'][bank]['fraud_count'] for bank in bank_names]
        
        # 1. Fraud rates by bank
        axes[0, 0].bar(bank_names, fraud_rates, color='coral', alpha=0.7)
        axes[0, 0].set_title('Fraud Rates by Bank')
        axes[0, 0].set_ylabel('Fraud Rate')
        axes[0, 0].tick_params(axis='x', rotation=45)
        
        # Add value labels on bars
        for i, v in enumerate(fraud_rates):
            axes[0, 0].text(i, v + 0.001, f'{v:.4f}', ha='center', va='bottom')
        
        # 2. Sample counts by bank
        axes[0, 1].bar(bank_names, sample_counts, color='skyblue', alpha=0.7)
        axes[0, 1].set_title('Sample Counts by Bank')
        axes[0, 1].set_ylabel('Number of Samples')
        axes[0, 1].tick_params(axis='x', rotation=45)
        
        # Add value labels on bars
        for i, v in enumerate(sample_counts):
            axes[0, 1].text(i, v + max(sample_counts) * 0.01, f'{v:,}', ha='center', va='bottom')
        
        # 3. Class distribution (stacked bar)
        safe_counts = [sample_counts[i] - fraud_counts[i] for i in range(len(bank_names))]
        
        axes[1, 0].bar(bank_names, safe_counts, label='Safe', color='lightgreen', alpha=0.7)
        axes[1, 0].bar(bank_names, fraud_counts, bottom=safe_counts, label='Fraud', color='red', alpha=0.7)
        axes[1, 0].set_title('Class Distribution by Bank')
        axes[1, 0].set_ylabel('Number of Samples')
        axes[1, 0].legend()
        axes[1, 0].tick_params(axis='x', rotation=45)
        
        # 4. Heterogeneity metrics
        het_metrics = self.partition_stats['heterogeneity']
        metrics_names = ['Fraud Rate Std', 'Sample Count Std', 'JS Divergence']
        metrics_values = [
            het_metrics['fraud_rate_std'],
            het_metrics['sample_count_std'] / max(sample_counts),  # Normalized
            het_metrics['js_divergence']
        ]
        
        axes[1, 1].bar(metrics_names, metrics_values, color=['orange', 'purple', 'brown'], alpha=0.7)
        axes[1, 1].set_title('Heterogeneity Metrics')
        axes[1, 1].set_ylabel('Normalized Values')
        axes[1, 1].tick_params(axis='x', rotation=45)
        
        # Add value labels
        for i, v in enumerate(metrics_values):
            axes[1, 1].text(i, v + max(metrics_values) * 0.01, f'{v:.4f}', ha='center', va='bottom')
        
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            logger.info(f"Partition visualization saved to: {save_path}")
        
        plt.show()
    
    def get_partition_quality_report(self) -> Dict[str, Any]:
        """
        Generate a comprehensive partition quality report.
        
        Returns:
            Dictionary containing quality metrics and recommendations
        """
        if not self.partition_stats:
            return {'error': 'No partition statistics available'}
        
        stats = self.partition_stats
        het = stats['heterogeneity']
        
        # Quality assessment
        quality_score = 0.0
        recommendations = []
        
        # 1. Check fraud rate heterogeneity (good if moderate variance)
        fraud_rate_cv = het['fraud_rate_std'] / np.mean([bank['fraud_rate'] for bank in stats['banks'].values()])
        if 0.1 <= fraud_rate_cv <= 0.5:
            quality_score += 25
        elif fraud_rate_cv < 0.1:
            recommendations.append("Fraud rate variance is low - consider more heterogeneous partitioning")
        else:
            recommendations.append("Fraud rate variance is very high - may impact convergence")
        
        # 2. Check sample balance (good if not too imbalanced)
        sample_counts = [bank['samples'] for bank in stats['banks'].values()]
        sample_ratio = max(sample_counts) / min(sample_counts)
        if sample_ratio <= 3:
            quality_score += 25
        elif sample_ratio <= 5:
            quality_score += 15
            recommendations.append("Moderate sample imbalance detected")
        else:
            recommendations.append("High sample imbalance - consider rebalancing")
        
        # 3. Check JS divergence (good if moderate)
        js_div = het['js_divergence']
        if 0.1 <= js_div <= 0.4:
            quality_score += 25
        elif js_div < 0.1:
            recommendations.append("Low distribution divergence - banks are too similar")
        else:
            recommendations.append("High distribution divergence - may impact federated learning")
        
        # 4. Check minimum samples per bank
        min_samples = min(sample_counts)
        if min_samples >= 5000:
            quality_score += 25
        elif min_samples >= 1000:
            quality_score += 15
            recommendations.append("Some banks have relatively few samples")
        else:
            recommendations.append("Some banks have very few samples - may impact training")
        
        # Overall assessment
        if quality_score >= 80:
            assessment = "Excellent"
        elif quality_score >= 60:
            assessment = "Good"
        elif quality_score >= 40:
            assessment = "Fair"
        else:
            assessment = "Poor"
        
        return {
            'quality_score': quality_score,
            'assessment': assessment,
            'recommendations': recommendations,
            'detailed_metrics': {
                'fraud_rate_cv': fraud_rate_cv,
                'sample_imbalance_ratio': sample_ratio,
                'js_divergence': js_div,
                'min_samples_per_bank': min_samples,
                'total_samples': stats['total_samples'],
                'num_banks': stats['num_banks']
            }
        }

def create_noniid_splits(X: np.ndarray, y: np.ndarray, strategy: str = "time_based", 
                        num_banks: int = 3, random_state: int = 42, 
                        **kwargs) -> Dict[str, Tuple[np.ndarray, np.ndarray]]:
    """
    Create non-IID splits for federated learning simulation.
    
    This is the main function used by other modules for data partitioning.
    
    Args:
        X: Feature matrix
        y: Target labels
        strategy: Partitioning strategy ('time_based', 'geographic', 'customer_segment')
        num_banks: Number of banks to simulate
        random_state: Random seed for reproducibility
        **kwargs: Additional strategy-specific parameters
        
    Returns:
        Dictionary mapping bank names to (X, y) tuples
    """
    partitioner = NonIIDPartitioner(random_state=random_state)
    bank_splits = partitioner.create_noniid_splits(X, y, strategy, num_banks, **kwargs)
    
    # Generate quality report
    quality_report = partitioner.get_partition_quality_report()
    logger.info(f"Partition Quality: {quality_report['assessment']} (Score: {quality_report['quality_score']}/100)")
    
    for recommendation in quality_report['recommendations']:
        logger.warning(f"Recommendation: {recommendation}")
    
    return bank_splits

def analyze_data_heterogeneity(bank_splits: Dict[str, Tuple[np.ndarray, np.ndarray]], 
                              feature_names: Optional[List[str]] = None) -> Dict[str, Any]:
    """
    Analyze heterogeneity across bank data splits.
    
    Args:
        bank_splits: Dictionary of bank data splits
        feature_names: Optional list of feature names
        
    Returns:
        Heterogeneity analysis results
    """
    logger.info("Analyzing data heterogeneity across banks")
    
    analysis = {
        'basic_stats': {},
        'feature_distributions': {},
        'correlation_differences': {},
        'statistical_tests': {}
    }
    
    # Basic statistics per bank
    for bank_name, (X, y) in bank_splits.items():
        analysis['basic_stats'][bank_name] = {
            'samples': len(X),
            'features': X.shape[1],
            'fraud_rate': float(y.mean()),
            'feature_means': X.mean(axis=0).tolist(),
            'feature_stds': X.std(axis=0).tolist()
        }
    
    # Feature distribution analysis
    if len(bank_splits) >= 2:
        bank_names = list(bank_splits.keys())
        
        # Compare feature distributions between first two banks
        X1, y1 = bank_splits[bank_names[0]]
        X2, y2 = bank_splits[bank_names[1]]
        
        # Kolmogorov-Smirnov test for feature distributions
        from scipy.stats import ks_2samp
        
        ks_statistics = []
        ks_pvalues = []
        
        for feature_idx in range(min(X1.shape[1], X2.shape[1], 20)):  # Limit to first 20 features
            try:
                ks_stat, ks_pval = ks_2samp(X1[:, feature_idx], X2[:, feature_idx])
                ks_statistics.append(float(ks_stat))
                ks_pvalues.append(float(ks_pval))
            except Exception as e:
                logger.warning(f"KS test failed for feature {feature_idx}: {e}")
                ks_statistics.append(0.0)
                ks_pvalues.append(1.0)
        
        analysis['statistical_tests'] = {
            'ks_statistics': ks_statistics,
            'ks_pvalues': ks_pvalues,
            'significant_differences': sum(1 for p in ks_pvalues if p < 0.05)
        }
    
    logger.info(f"Heterogeneity analysis completed for {len(bank_splits)} banks")
    
    return analysis

def save_partition_results(bank_splits: Dict[str, Tuple[np.ndarray, np.ndarray]], 
                          partition_stats: Dict[str, Any], filepath: str) -> None:
    """
    Save partition results and statistics.
    
    Args:
        bank_splits: Dictionary of bank data splits
        partition_stats: Partition statistics
        filepath: Path to save results
    """
    import pickle
    import os
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    # Prepare save data
    save_data = {
        'bank_splits': bank_splits,
        'partition_stats': partition_stats,
        'metadata': {
            'timestamp': datetime.now().isoformat(),
            'num_banks': len(bank_splits),
            'total_samples': sum(len(X) for X, _ in bank_splits.values())
        }
    }
    
    # Save to file
    with open(filepath, 'wb') as f:
        pickle.dump(save_data, f, protocol=pickle.HIGHEST_PROTOCOL)
    
    logger.info(f"Partition results saved to: {filepath}")

def load_partition_results(filepath: str) -> Tuple[Dict[str, Tuple[np.ndarray, np.ndarray]], Dict[str, Any]]:
    """
    Load partition results and statistics.
    
    Args:
        filepath: Path to load results from
        
    Returns:
        Tuple of (bank_splits, partition_stats)
    """
    import pickle
    
    with open(filepath, 'rb') as f:
        save_data = pickle.load(f)
    
    logger.info(f"Partition results loaded from: {filepath}")
    
    return save_data['bank_splits'], save_data['partition_stats']

# Export main functions
__all__ = [
    'NonIIDPartitioner',
    'create_noniid_splits',
    'analyze_data_heterogeneity',
    'save_partition_results',
    'load_partition_results'
]