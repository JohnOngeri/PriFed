"""
Advanced Data Loading and Preprocessing Pipeline for PrivFed Fraud Detection System.
Implements IEEE-CIS fraud detection dataset processing with sophisticated feature engineering,
multi-strategy preprocessing, and federated learning data preparation.

This module provides enterprise-grade data processing capabilities including:
- Robust data loading with validation and error handling
- Advanced feature engineering and selection
- Multiple preprocessing strategies for different training paradigms
- Comprehensive data quality assessment and monitoring
- Memory-efficient processing for large datasets
- Extensive logging and debugging capabilities
"""

import os
import pandas as pd
import numpy as np
from typing import Tuple, Dict, List, Optional, Any, Union
from sklearn.preprocessing import StandardScaler, RobustScaler, MinMaxScaler, LabelEncoder, OneHotEncoder, TargetEncoder
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.impute import SimpleImputer, KNNImputer, IterativeImputer
from sklearn.feature_selection import SelectKBest, f_classif, mutual_info_classif, RFE
from sklearn.decomposition import PCA
from sklearn.ensemble import RandomForestClassifier
import torch
from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
import logging
import yaml
import pickle
import json
import warnings
from pathlib import Path
from datetime import datetime
import hashlib
from collections import Counter, defaultdict
import gc
import psutil

# Suppress warnings for cleaner output
warnings.filterwarnings('ignore')

logger = logging.getLogger(__name__)

class AdvancedFraudDataset(Dataset):
    """
    Advanced PyTorch Dataset for fraud detection with sophisticated sampling and augmentation.
    Supports weighted sampling, data augmentation, and memory-efficient loading.
    """
    
    def __init__(self, X: np.ndarray, y: np.ndarray, 
                 sample_weights: Optional[np.ndarray] = None,
                 augment_minority: bool = False,
                 noise_factor: float = 0.01):
        """
        Initialize advanced fraud dataset.
        
        Args:
            X: Feature matrix
            y: Target labels
            sample_weights: Optional sample weights for balanced training
            augment_minority: Whether to augment minority class samples
            noise_factor: Noise factor for data augmentation
        """
        self.X = torch.FloatTensor(X)
        self.y = torch.FloatTensor(y)
        self.sample_weights = sample_weights
        self.augment_minority = augment_minority
        self.noise_factor = noise_factor
        
        # Calculate class statistics
        self.class_counts = Counter(y.astype(int))
        self.fraud_rate = self.class_counts[1] / len(y)
        
        # Identify minority class samples for augmentation
        if augment_minority:
            self.minority_indices = np.where(y == 1)[0]
            
        logger.info(f"Dataset initialized: {len(X)} samples, fraud rate: {self.fraud_rate:.4f}")
    
    def __len__(self) -> int:
        return len(self.X)
    
    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
        x = self.X[idx]
        y = self.y[idx]
        
        # Apply data augmentation for minority class
        if self.augment_minority and y == 1 and np.random.random() < 0.3:
            noise = torch.randn_like(x) * self.noise_factor
            x = x + noise
        
        # Return sample weight if available
        weight = torch.tensor(1.0)
        if self.sample_weights is not None:
            weight = torch.tensor(self.sample_weights[idx])
            
        return x, y, weight

class DataQualityAssessment:
    """
    Comprehensive data quality assessment and monitoring system.
    Provides detailed analysis of data characteristics, quality issues, and recommendations.
    """
    
    def __init__(self):
        self.assessment_results = {}
        
    def assess_data_quality(self, df: pd.DataFrame, target_col: str = 'isFraud') -> Dict[str, Any]:
        """
        Perform comprehensive data quality assessment.
        
        Args:
            df: Input dataframe
            target_col: Target column name
            
        Returns:
            Dictionary containing quality assessment results
        """
        logger.info("Starting comprehensive data quality assessment...")
        
        results = {
            'basic_stats': self._get_basic_statistics(df),
            'missing_data': self._analyze_missing_data(df),
            'data_types': self._analyze_data_types(df),
            'target_distribution': self._analyze_target_distribution(df, target_col),
            'feature_correlations': self._analyze_feature_correlations(df, target_col),
            'outliers': self._detect_outliers(df),
            'data_drift': self._detect_potential_drift(df),
            'feature_importance': self._estimate_feature_importance(df, target_col),
            'recommendations': []
        }
        
        # Generate recommendations based on assessment
        results['recommendations'] = self._generate_recommendations(results)
        
        self.assessment_results = results
        logger.info("Data quality assessment completed")
        
        return results
    
    def _get_basic_statistics(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Get basic dataset statistics."""
        return {
            'num_samples': len(df),
            'num_features': len(df.columns),
            'memory_usage_mb': df.memory_usage(deep=True).sum() / 1024**2,
            'duplicate_rows': df.duplicated().sum(),
            'unique_values_per_column': df.nunique().to_dict()
        }
    
    def _analyze_missing_data(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Analyze missing data patterns."""
        missing_counts = df.isnull().sum()
        missing_percentages = (missing_counts / len(df)) * 100
        
        return {
            'total_missing': missing_counts.sum(),
            'missing_by_column': missing_counts.to_dict(),
            'missing_percentages': missing_percentages.to_dict(),
            'columns_with_high_missing': missing_percentages[missing_percentages > 50].index.tolist(),
            'completely_missing_columns': missing_percentages[missing_percentages == 100].index.tolist()
        }
    
    def _analyze_data_types(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Analyze data types and suggest optimizations."""
        type_counts = df.dtypes.value_counts().to_dict()
        
        # Identify potential type optimization opportunities
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        categorical_cols = df.select_dtypes(include=['object']).columns
        
        high_cardinality_cats = []
        for col in categorical_cols:
            if df[col].nunique() > 100:
                high_cardinality_cats.append(col)
        
        return {
            'type_distribution': {str(k): v for k, v in type_counts.items()},
            'numeric_columns': numeric_cols.tolist(),
            'categorical_columns': categorical_cols.tolist(),
            'high_cardinality_categorical': high_cardinality_cats,
            'potential_categorical_as_numeric': []  # Could be enhanced with heuristics
        }
    
    def _analyze_target_distribution(self, df: pd.DataFrame, target_col: str) -> Dict[str, Any]:
        """Analyze target variable distribution."""
        if target_col not in df.columns:
            return {'error': f'Target column {target_col} not found'}
        
        target_counts = df[target_col].value_counts()
        
        return {
            'class_distribution': target_counts.to_dict(),
            'class_percentages': (target_counts / len(df) * 100).to_dict(),
            'imbalance_ratio': target_counts.max() / target_counts.min(),
            'is_highly_imbalanced': (target_counts.min() / target_counts.max()) < 0.1
        }
    
    def _analyze_feature_correlations(self, df: pd.DataFrame, target_col: str) -> Dict[str, Any]:
        """Analyze feature correlations with target and among features."""
        numeric_df = df.select_dtypes(include=[np.number])
        
        if target_col in numeric_df.columns:
            target_correlations = numeric_df.corr()[target_col].abs().sort_values(ascending=False)
            target_correlations = target_correlations.drop(target_col)
            
            # Find highly correlated feature pairs
            corr_matrix = numeric_df.corr().abs()
            high_corr_pairs = []
            
            for i in range(len(corr_matrix.columns)):
                for j in range(i+1, len(corr_matrix.columns)):
                    if corr_matrix.iloc[i, j] > 0.8:
                        high_corr_pairs.append({
                            'feature1': corr_matrix.columns[i],
                            'feature2': corr_matrix.columns[j],
                            'correlation': corr_matrix.iloc[i, j]
                        })
            
            return {
                'target_correlations': target_correlations.head(20).to_dict(),
                'highly_correlated_pairs': high_corr_pairs,
                'num_high_correlations': len(high_corr_pairs)
            }
        
        return {'error': 'Target column not numeric or not found'}
    
    def _detect_outliers(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Detect outliers using multiple methods."""
        numeric_df = df.select_dtypes(include=[np.number])
        outlier_summary = {}
        
        for col in numeric_df.columns:
            if col == 'isFraud':  # Skip target column
                continue
                
            Q1 = numeric_df[col].quantile(0.25)
            Q3 = numeric_df[col].quantile(0.75)
            IQR = Q3 - Q1
            
            lower_bound = Q1 - 1.5 * IQR
            upper_bound = Q3 + 1.5 * IQR
            
            outliers = numeric_df[(numeric_df[col] < lower_bound) | (numeric_df[col] > upper_bound)][col]
            
            outlier_summary[col] = {
                'count': len(outliers),
                'percentage': len(outliers) / len(numeric_df) * 100,
                'bounds': {'lower': lower_bound, 'upper': upper_bound}
            }
        
        return outlier_summary
    
    def _detect_potential_drift(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Detect potential data drift indicators."""
        # This is a simplified version - in practice, you'd compare with historical data
        drift_indicators = {
            'timestamp_gaps': False,
            'unusual_distributions': [],
            'potential_drift_features': []
        }
        
        # Check for timestamp-related features that might indicate drift
        timestamp_cols = [col for col in df.columns if 'time' in col.lower() or 'date' in col.lower() or 'dt' in col.lower()]
        
        if timestamp_cols:
            drift_indicators['has_timestamp_features'] = True
            drift_indicators['timestamp_columns'] = timestamp_cols
        
        return drift_indicators
    
    def _estimate_feature_importance(self, df: pd.DataFrame, target_col: str) -> Dict[str, Any]:
        """Estimate feature importance using multiple methods."""
        if target_col not in df.columns:
            return {'error': 'Target column not found'}
        
        # Prepare data for feature importance estimation
        numeric_df = df.select_dtypes(include=[np.number])
        if target_col not in numeric_df.columns:
            return {'error': 'Target column not numeric'}
        
        X = numeric_df.drop(columns=[target_col])
        y = numeric_df[target_col]
        
        # Remove columns with all NaN values
        X = X.dropna(axis=1, how='all')
        
        # Simple imputation for feature importance estimation
        X_filled = X.fillna(X.median())
        
        try:
            # Mutual information
            mi_scores = mutual_info_classif(X_filled, y, random_state=42)
            mi_importance = dict(zip(X.columns, mi_scores))
            
            # F-statistic
            f_scores, _ = f_classif(X_filled, y)
            f_importance = dict(zip(X.columns, f_scores))
            
            return {
                'mutual_information': dict(sorted(mi_importance.items(), key=lambda x: x[1], reverse=True)[:20]),
                'f_statistic': dict(sorted(f_importance.items(), key=lambda x: x[1], reverse=True)[:20])
            }
        except Exception as e:
            return {'error': f'Feature importance estimation failed: {str(e)}'}
    
    def _generate_recommendations(self, results: Dict[str, Any]) -> List[str]:
        """Generate data quality recommendations."""
        recommendations = []
        
        # Missing data recommendations
        missing_data = results.get('missing_data', {})
        if missing_data.get('total_missing', 0) > 0:
            recommendations.append("Consider advanced imputation strategies for missing data")
            
        high_missing_cols = missing_data.get('columns_with_high_missing', [])
        if high_missing_cols:
            recommendations.append(f"Consider removing columns with >50% missing data: {high_missing_cols[:5]}")
        
        # Imbalance recommendations
        target_dist = results.get('target_distribution', {})
        if target_dist.get('is_highly_imbalanced', False):
            recommendations.append("Dataset is highly imbalanced - consider SMOTE, class weights, or ensemble methods")
        
        # Correlation recommendations
        correlations = results.get('feature_correlations', {})
        if correlations.get('num_high_correlations', 0) > 10:
            recommendations.append("Many highly correlated features detected - consider dimensionality reduction")
        
        # Outlier recommendations
        outliers = results.get('outliers', {})
        high_outlier_cols = [col for col, info in outliers.items() 
                           if isinstance(info, dict) and info.get('percentage', 0) > 5]
        if high_outlier_cols:
            recommendations.append(f"High outlier percentage in columns: {high_outlier_cols[:5]}")
        
        return recommendations

class AdvancedFeatureEngineering:
    """
    Advanced feature engineering pipeline with domain-specific transformations
    for fraud detection and federated learning optimization.
    """
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.feature_transformers = {}
        self.feature_metadata = {}
        
    def engineer_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Apply comprehensive feature engineering pipeline.
        
        Args:
            df: Input dataframe
            
        Returns:
            Dataframe with engineered features
        """
        logger.info("Starting advanced feature engineering...")
        
        df_engineered = df.copy()
        
        # Transaction amount features
        df_engineered = self._engineer_transaction_features(df_engineered)
        
        # Temporal features
        df_engineered = self._engineer_temporal_features(df_engineered)
        
        # Card and payment features
        df_engineered = self._engineer_payment_features(df_engineered)
        
        # Identity and device features
        df_engineered = self._engineer_identity_features(df_engineered)
        
        # Interaction features
        df_engineered = self._engineer_interaction_features(df_engineered)
        
        # Aggregation features
        df_engineered = self._engineer_aggregation_features(df_engineered)
        
        logger.info(f"Feature engineering completed. Features: {len(df.columns)} -> {len(df_engineered.columns)}")
        
        return df_engineered
    
    def _engineer_transaction_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Engineer transaction amount related features."""
        if 'TransactionAmt' in df.columns:
            # Log transformation
            df['TransactionAmt_log'] = np.log1p(df['TransactionAmt'])
            
            # Amount bins
            df['TransactionAmt_bin'] = pd.cut(df['TransactionAmt'], 
                                            bins=[0, 50, 100, 500, 1000, np.inf], 
                                            labels=['very_low', 'low', 'medium', 'high', 'very_high'])
            
            # Round amount indicators
            df['is_round_amount'] = (df['TransactionAmt'] % 1 == 0).astype(int)
            df['is_round_10'] = (df['TransactionAmt'] % 10 == 0).astype(int)
            df['is_round_100'] = (df['TransactionAmt'] % 100 == 0).astype(int)
            
            # Decimal places
            df['decimal_places'] = df['TransactionAmt'].apply(
                lambda x: len(str(x).split('.')[-1]) if '.' in str(x) else 0
            )
        
        return df
    
    def _engineer_temporal_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Engineer temporal features from TransactionDT."""
        if 'TransactionDT' in df.columns:
            # Convert to datetime-like features
            df['hour'] = (df['TransactionDT'] / 3600) % 24
            df['day'] = (df['TransactionDT'] / (3600 * 24)) % 7
            df['week'] = (df['TransactionDT'] / (3600 * 24 * 7)) % 52
            
            # Time-based bins
            df['time_of_day'] = pd.cut(df['hour'], 
                                     bins=[0, 6, 12, 18, 24], 
                                     labels=['night', 'morning', 'afternoon', 'evening'],
                                     include_lowest=True)
            
            # Weekend indicator
            df['is_weekend'] = (df['day'] >= 5).astype(int)
            
            # Business hours
            df['is_business_hours'] = ((df['hour'] >= 9) & (df['hour'] <= 17)).astype(int)
        
        return df
    
    def _engineer_payment_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Engineer payment and card related features."""
        # Card features
        card_cols = [col for col in df.columns if col.startswith('card')]
        for col in card_cols:
            if df[col].dtype in ['int64', 'float64']:
                # Card number patterns
                df[f'{col}_last_digit'] = df[col] % 10
                df[f'{col}_first_digit'] = df[col].astype(str).str[0].astype(float)
        
        # Product code features
        if 'ProductCD' in df.columns:
            df['ProductCD_encoded'] = LabelEncoder().fit_transform(df['ProductCD'].fillna('Unknown'))
        
        return df
    
    def _engineer_identity_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Engineer identity and device features."""
        # Email domain features
        email_cols = [col for col in df.columns if 'email' in col.lower()]
        for col in email_cols:
            if col in df.columns:
                df[f'{col}_is_gmail'] = df[col].str.contains('gmail', na=False).astype(int)
                df[f'{col}_is_yahoo'] = df[col].str.contains('yahoo', na=False).astype(int)
                df[f'{col}_domain_length'] = df[col].str.len().fillna(0)
        
        # Device info features
        device_cols = [col for col in df.columns if 'device' in col.lower() or 'id_' in col]
        for col in device_cols[:10]:  # Limit to avoid too many features
            if col in df.columns and df[col].dtype == 'object':
                # Encode categorical device features
                df[f'{col}_encoded'] = LabelEncoder().fit_transform(df[col].fillna('Unknown'))
        
        return df
    
    def _engineer_interaction_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Engineer interaction features between important variables."""
        # Amount and card interactions
        if 'TransactionAmt' in df.columns and 'card1' in df.columns:
            df['amt_card1_ratio'] = df['TransactionAmt'] / (df['card1'] + 1)
        
        # Distance features interactions
        if 'dist1' in df.columns and 'dist2' in df.columns:
            df['dist_sum'] = df['dist1'].fillna(0) + df['dist2'].fillna(0)
            df['dist_diff'] = abs(df['dist1'].fillna(0) - df['dist2'].fillna(0))
        
        return df
    
    def _engineer_aggregation_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Engineer aggregation features (simplified version)."""
        # This would typically involve groupby operations on user/card level
        # For now, we'll create some basic statistical features
        
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        
        # Create some basic aggregation features
        if len(numeric_cols) > 5:
            # Select a subset for aggregation to avoid too many features
            agg_cols = numeric_cols[:5]
            
            for col in agg_cols:
                if col not in ['TransactionID', 'isFraud']:
                    # Percentile-based features
                    df[f'{col}_percentile'] = pd.qcut(df[col].fillna(df[col].median()), 
                                                    q=5, labels=False, duplicates='drop')
        
        return df

def load_config(config_path: str = "configs/config.yaml") -> Dict[str, Any]:
    """
    Load configuration from YAML file with validation and defaults.
    
    Args:
        config_path: Path to configuration file
        
    Returns:
        Configuration dictionary with validated parameters
    """
    try:
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)
        
        # Validate required sections
        required_sections = ['data', 'model', 'federated_learning', 'differential_privacy', 'experiment']
        for section in required_sections:
            if section not in config:
                logger.warning(f"Missing configuration section: {section}")
                config[section] = {}
        
        # Set defaults for missing values
        config = _set_config_defaults(config)
        
        logger.info(f"Configuration loaded successfully from {config_path}")
        return config
        
    except FileNotFoundError:
        logger.error(f"Configuration file not found: {config_path}")
        return _get_default_config()
    except yaml.YAMLError as e:
        logger.error(f"Error parsing configuration file: {e}")
        return _get_default_config()

def _set_config_defaults(config: Dict[str, Any]) -> Dict[str, Any]:
    """Set default values for missing configuration parameters."""
    defaults = {
        'data': {
            'dataset_path': "C:\\Users\\HP\\OneDrive\\Desktop\\PrivFed\\dataset",
            'test_size': 0.2,
            'val_size': 0.2,
            'random_state': 42,
            'partition_strategy': 'time_based',
            'num_banks': 3
        },
        'model': {
            'hidden_layers': [256, 128, 64],
            'dropout_rate': 0.3,
            'learning_rate': 0.001,
            'batch_size': 512,
            'local_epochs': 5
        },
        'experiment': {
            'seed': 42,
            'device': 'auto'
        }
    }
    
    for section, section_defaults in defaults.items():
        for key, value in section_defaults.items():
            if key not in config[section]:
                config[section][key] = value
    
    return config

def _get_default_config() -> Dict[str, Any]:
    """Get default configuration when config file is not available."""
    return {
        'data': {
            'dataset_path': "C:\\Users\\HP\\OneDrive\\Desktop\\PrivFed\\dataset",
            'train_transaction': "train_transaction.csv",
            'train_identity': "train_identity.csv",
            'test_transaction': "test_transaction.csv",
            'test_identity': "test_identity.csv",
            'test_size': 0.2,
            'val_size': 0.2,
            'random_state': 42,
            'partition_strategy': 'time_based',
            'num_banks': 3
        },
        'model': {
            'hidden_layers': [256, 128, 64],
            'dropout_rate': 0.3,
            'activation': 'relu',
            'batch_norm': True,
            'learning_rate': 0.001,
            'batch_size': 512,
            'local_epochs': 5,
            'weight_decay': 1e-5
        },
        'federated_learning': {
            'num_rounds': 50,
            'clients_per_round': 3,
            'min_fit_clients': 2,
            'min_evaluate_clients': 2,
            'min_available_clients': 3,
            'strategy': 'FedAvg'
        },
        'differential_privacy': {
            'enabled': False,
            'noise_multiplier': 1.1,
            'max_grad_norm': 1.0,
            'target_epsilon': 8.0,
            'target_delta': 1e-5
        },
        'experiment': {
            'name': 'privfed_fraud_detection',
            'seed': 42,
            'device': 'auto',
            'log_level': 'INFO'
        }
    }

def load_raw_data(config: Dict[str, Any]) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Load raw IEEE-CIS fraud detection dataset with comprehensive validation and error handling.
    
    Args:
        config: Configuration dictionary containing data paths
        
    Returns:
        Tuple of (train_transaction, train_identity, test_transaction, test_identity)
    """
    data_config = config['data']
    dataset_path = Path(data_config['dataset_path'])
    
    # Validate dataset path exists
    if not dataset_path.exists():
        raise FileNotFoundError(f"Dataset directory not found: {dataset_path}")
    
    # Define file paths
    file_paths = {
        'train_transaction': dataset_path / data_config['train_transaction'],
        'train_identity': dataset_path / data_config['train_identity'],
        'test_transaction': dataset_path / data_config['test_transaction'],
        'test_identity': dataset_path / data_config['test_identity']
    }
    
    # Validate all files exist
    for name, path in file_paths.items():
        if not path.exists():
            raise FileNotFoundError(f"{name} file not found: {path}")
    
    logger.info("Loading IEEE-CIS fraud detection dataset...")
    
    # Load datasets with progress tracking
    datasets = {}
    
    for name, path in file_paths.items():
        logger.info(f"Loading {name} from: {path}")
        
        try:
            # Load with optimized dtypes for memory efficiency
            df = pd.read_csv(path, low_memory=False)
            datasets[name] = df
            
            logger.info(f"  {name}: {df.shape[0]:,} rows, {df.shape[1]:,} columns")
            logger.info(f"  Memory usage: {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
            
        except Exception as e:
            logger.error(f"Error loading {name}: {e}")
            raise
    
    # Log dataset overview
    total_memory = sum(df.memory_usage(deep=True).sum() for df in datasets.values()) / 1024**2
    logger.info(f"Total dataset memory usage: {total_memory:.2f} MB")
    
    # Perform basic validation
    _validate_dataset_integrity(datasets)
    
    return (datasets['train_transaction'], datasets['train_identity'], 
            datasets['test_transaction'], datasets['test_identity'])

def _validate_dataset_integrity(datasets: Dict[str, pd.DataFrame]) -> None:
    """Validate dataset integrity and consistency."""
    train_trans = datasets['train_transaction']
    train_identity = datasets['train_identity']
    
    # Check for required columns
    required_cols = {
        'train_transaction': ['TransactionID', 'isFraud', 'TransactionDT', 'TransactionAmt'],
        'train_identity': ['TransactionID']
    }
    
    for dataset_name, required in required_cols.items():
        if dataset_name in datasets:
            df = datasets[dataset_name]
            missing_cols = [col for col in required if col not in df.columns]
            if missing_cols:
                raise ValueError(f"Missing required columns in {dataset_name}: {missing_cols}")
    
    # Check TransactionID consistency
    train_trans_ids = set(train_trans['TransactionID'])
    train_identity_ids = set(train_identity['TransactionID'])
    
    overlap = len(train_trans_ids.intersection(train_identity_ids))
    logger.info(f"Transaction-Identity ID overlap: {overlap:,} / {len(train_trans_ids):,} ({overlap/len(train_trans_ids)*100:.1f}%)")
    
    # Check target distribution
    fraud_rate = train_trans['isFraud'].mean()
    logger.info(f"Fraud rate in training data: {fraud_rate:.4f} ({fraud_rate*100:.2f}%)")
    
    if fraud_rate < 0.001 or fraud_rate > 0.5:
        logger.warning(f"Unusual fraud rate detected: {fraud_rate:.4f}")

def merge_transaction_identity(transaction_df: pd.DataFrame, identity_df: pd.DataFrame, 
                             how: str = 'left') -> pd.DataFrame:
    """
    Merge transaction and identity dataframes with comprehensive validation.
    
    Args:
        transaction_df: Transaction features dataframe
        identity_df: Identity features dataframe
        how: Type of merge ('left', 'inner', 'outer')
        
    Returns:
        Merged dataframe with validation metrics
    """
    logger.info(f"Merging transaction and identity data using '{how}' join...")
    
    # Validate merge key
    if 'TransactionID' not in transaction_df.columns:
        raise ValueError("TransactionID not found in transaction dataframe")
    if 'TransactionID' not in identity_df.columns:
        raise ValueError("TransactionID not found in identity dataframe")
    
    # Check for duplicates
    trans_dups = transaction_df['TransactionID'].duplicated().sum()
    identity_dups = identity_df['TransactionID'].duplicated().sum()
    
    if trans_dups > 0:
        logger.warning(f"Found {trans_dups} duplicate TransactionIDs in transaction data")
    if identity_dups > 0:
        logger.warning(f"Found {identity_dups} duplicate TransactionIDs in identity data")
    
    # Perform merge
    merged_df = transaction_df.merge(identity_df, on='TransactionID', how=how, suffixes=('', '_identity'))
    
    # Log merge statistics
    logger.info(f"Merge completed:")
    logger.info(f"  Transaction records: {len(transaction_df):,}")
    logger.info(f"  Identity records: {len(identity_df):,}")
    logger.info(f"  Merged records: {len(merged_df):,}")
    logger.info(f"  Features: {len(transaction_df.columns)} + {len(identity_df.columns)-1} = {len(merged_df.columns)}")
    
    # Check for merge quality
    if how == 'left':
        match_rate = (merged_df.iloc[:, len(transaction_df.columns):].notna().any(axis=1)).mean()
        logger.info(f"  Identity match rate: {match_rate:.4f} ({match_rate*100:.2f}%)")
    
    return merged_df

def advanced_preprocessing_pipeline(df: pd.DataFrame, is_training: bool = True, 
                                  preprocessing_artifacts: Optional[Dict] = None,
                                  config: Optional[Dict[str, Any]] = None) -> Tuple[np.ndarray, Optional[np.ndarray], Dict]:
    """
    Advanced preprocessing pipeline with multiple strategies and comprehensive feature engineering.
    
    Args:
        df: Input dataframe
        is_training: Whether this is training data
        preprocessing_artifacts: Pre-fitted preprocessing objects
        config: Configuration dictionary
        
    Returns:
        Tuple of (X, y, preprocessing_artifacts)
    """
    logger.info("Starting advanced preprocessing pipeline...")
    
    if config is None:
        config = _get_default_config()
    
    if preprocessing_artifacts is None:
        preprocessing_artifacts = {}
    
    df_processed = df.copy()
    
    # Separate target variable
    y = None
    if 'isFraud' in df_processed.columns:
        y = df_processed['isFraud'].values
        df_processed = df_processed.drop(['isFraud'], axis=1)
    
    # Remove ID columns
    id_columns = ['TransactionID']
    df_processed = df_processed.drop([col for col in id_columns if col in df_processed.columns], axis=1)
    
    # Apply feature engineering
    if is_training or 'feature_engineer' not in preprocessing_artifacts:
        feature_engineer = AdvancedFeatureEngineering(config)
        df_processed = feature_engineer.engineer_features(df_processed)
        if is_training:
            preprocessing_artifacts['feature_engineer'] = feature_engineer
    else:
        df_processed = preprocessing_artifacts['feature_engineer'].engineer_features(df_processed)
    
    # Identify feature types
    numeric_features = []
    categorical_features = []
    
    for col in df_processed.columns:
        if df_processed[col].dtype in ['int64', 'float64']:
            if df_processed[col].nunique() <= 50 and col.startswith(('C', 'D', 'M')):
                categorical_features.append(col)
            else:
                numeric_features.append(col)
        else:
            categorical_features.append(col)
    
    logger.info(f"Feature types identified: {len(numeric_features)} numeric, {len(categorical_features)} categorical")
    
    # Advanced missing value imputation
    df_processed = _advanced_missing_value_imputation(
        df_processed, numeric_features, categorical_features, 
        is_training, preprocessing_artifacts
    )
    
    # Feature encoding
    df_processed = _advanced_feature_encoding(
        df_processed, categorical_features, y,
        is_training, preprocessing_artifacts
    )
    
    # Feature selection
    if is_training and len(df_processed.columns) > 100:
        df_processed = _advanced_feature_selection(
            df_processed, y, preprocessing_artifacts, config
        )
    elif 'selected_features' in preprocessing_artifacts:
        selected_features = preprocessing_artifacts['selected_features']
        available_features = [f for f in selected_features if f in df_processed.columns]
        df_processed = df_processed[available_features]
    
    # Feature scaling
    numeric_features = [col for col in df_processed.columns 
                       if df_processed[col].dtype in ['int64', 'float64']]
    
    if numeric_features:
        df_processed = _advanced_feature_scaling(
            df_processed, numeric_features, is_training, preprocessing_artifacts
        )
    
    # Convert to numpy array
    X = df_processed.values.astype(np.float32)
    
    # Handle any remaining NaN values
    if np.isnan(X).any():
        logger.warning("NaN values detected after preprocessing, filling with 0")
        X = np.nan_to_num(X, nan=0.0)
    
    logger.info(f"Preprocessing completed: {X.shape[0]} samples, {X.shape[1]} features")
    
    if y is not None:
        fraud_rate = y.mean()
        logger.info(f"Target distribution: {np.bincount(y.astype(int))}, fraud rate: {fraud_rate:.4f}")
    
    # Store feature names for interpretability
    preprocessing_artifacts['feature_names'] = list(df_processed.columns)
    preprocessing_artifacts['feature_count'] = X.shape[1]
    
    return X, y, preprocessing_artifacts

def _advanced_missing_value_imputation(df: pd.DataFrame, numeric_features: List[str], 
                                     categorical_features: List[str], is_training: bool,
                                     artifacts: Dict) -> pd.DataFrame:
    """Advanced missing value imputation with multiple strategies."""
    logger.info("Applying advanced missing value imputation...")
    
    df_imputed = df.copy()
    
    # Numeric features - use multiple imputation strategies
    if numeric_features:
        if is_training:
            # Choose imputation strategy based on missing percentage
            missing_percentages = df[numeric_features].isnull().mean()
            
            # Low missing: median imputation
            low_missing = missing_percentages[missing_percentages <= 0.1].index.tolist()
            # Medium missing: KNN imputation
            medium_missing = missing_percentages[(missing_percentages > 0.1) & (missing_percentages <= 0.3)].index.tolist()
            # High missing: iterative imputation
            high_missing = missing_percentages[missing_percentages > 0.3].index.tolist()
            
            artifacts['imputation_strategy'] = {
                'low_missing': low_missing,
                'medium_missing': medium_missing,
                'high_missing': high_missing
            }
            
            # Apply different imputation strategies
            if low_missing:
                artifacts['median_imputer'] = SimpleImputer(strategy='median')
                df_imputed[low_missing] = artifacts['median_imputer'].fit_transform(df_imputed[low_missing])
            
            if medium_missing and len(medium_missing) <= 20:  # Limit for performance
                artifacts['knn_imputer'] = KNNImputer(n_neighbors=5)
                df_imputed[medium_missing] = artifacts['knn_imputer'].fit_transform(df_imputed[medium_missing])
            
            if high_missing and len(high_missing) <= 10:  # Limit for performance
                artifacts['iterative_imputer'] = IterativeImputer(random_state=42, max_iter=10)
                df_imputed[high_missing] = artifacts['iterative_imputer'].fit_transform(df_imputed[high_missing])
        
        else:
            # Apply pre-fitted imputers
            strategy = artifacts.get('imputation_strategy', {})
            
            if 'median_imputer' in artifacts and strategy.get('low_missing'):
                low_missing = [col for col in strategy['low_missing'] if col in df_imputed.columns]
                if low_missing:
                    df_imputed[low_missing] = artifacts['median_imputer'].transform(df_imputed[low_missing])
            
            if 'knn_imputer' in artifacts and strategy.get('medium_missing'):
                medium_missing = [col for col in strategy['medium_missing'] if col in df_imputed.columns]
                if medium_missing:
                    df_imputed[medium_missing] = artifacts['knn_imputer'].transform(df_imputed[medium_missing])
            
            if 'iterative_imputer' in artifacts and strategy.get('high_missing'):
                high_missing = [col for col in strategy['high_missing'] if col in df_imputed.columns]
                if high_missing:
                    df_imputed[high_missing] = artifacts['iterative_imputer'].transform(df_imputed[high_missing])
    
    # Categorical features - mode imputation
    if categorical_features:
        if is_training:
            artifacts['categorical_imputer'] = SimpleImputer(strategy='most_frequent')
            df_imputed[categorical_features] = artifacts['categorical_imputer'].fit_transform(df_imputed[categorical_features])
        else:
            if 'categorical_imputer' in artifacts:
                cat_features = [col for col in categorical_features if col in df_imputed.columns]
                if cat_features:
                    df_imputed[cat_features] = artifacts['categorical_imputer'].transform(df_imputed[cat_features])
    
    return df_imputed

def _advanced_feature_encoding(df: pd.DataFrame, categorical_features: List[str], 
                             y: Optional[np.ndarray], is_training: bool, 
                             artifacts: Dict) -> pd.DataFrame:
    """Advanced feature encoding with multiple strategies."""
    logger.info("Applying advanced feature encoding...")
    
    df_encoded = df.copy()
    
    for col in categorical_features:
        if col not in df_encoded.columns:
            continue
            
        unique_count = df_encoded[col].nunique()
        
        if is_training:
            if unique_count <= 10:
                # One-hot encoding for low cardinality
                encoder = OneHotEncoder(sparse_output=False, handle_unknown='ignore', drop='first')
                encoded_cols = encoder.fit_transform(df_encoded[[col]])
                feature_names = [f"{col}_{cat}" for cat in encoder.categories_[0][1:]]  # Skip first due to drop='first'
                
                # Add encoded columns
                encoded_df = pd.DataFrame(encoded_cols, columns=feature_names, index=df_encoded.index)
                df_encoded = pd.concat([df_encoded.drop(columns=[col]), encoded_df], axis=1)
                
                artifacts[f'encoder_{col}'] = encoder
                artifacts[f'encoder_type_{col}'] = 'onehot'
                
            elif unique_count <= 100 and y is not None:
                # Target encoding for medium cardinality
                encoder = TargetEncoder()
                df_encoded[col] = encoder.fit_transform(df_encoded[[col]], y)
                
                artifacts[f'encoder_{col}'] = encoder
                artifacts[f'encoder_type_{col}'] = 'target'
                
            else:
                # Label encoding for high cardinality
                encoder = LabelEncoder()
                df_encoded[col] = encoder.fit_transform(df_encoded[col].astype(str))
                
                artifacts[f'encoder_{col}'] = encoder
                artifacts[f'encoder_type_{col}'] = 'label'
        
        else:
            # Apply pre-fitted encoders
            encoder_key = f'encoder_{col}'
            encoder_type_key = f'encoder_type_{col}'
            
            if encoder_key in artifacts:
                encoder = artifacts[encoder_key]
                encoder_type = artifacts.get(encoder_type_key, 'label')
                
                if encoder_type == 'onehot':
                    try:
                        encoded_cols = encoder.transform(df_encoded[[col]])
                        feature_names = [f"{col}_{cat}" for cat in encoder.categories_[0][1:]]
                        encoded_df = pd.DataFrame(encoded_cols, columns=feature_names, index=df_encoded.index)
                        df_encoded = pd.concat([df_encoded.drop(columns=[col]), encoded_df], axis=1)
                    except Exception as e:
                        logger.warning(f"Error applying one-hot encoder for {col}: {e}")
                        df_encoded[col] = 0  # Default value
                
                elif encoder_type == 'target':
                    try:
                        df_encoded[col] = encoder.transform(df_encoded[[col]])
                    except Exception as e:
                        logger.warning(f"Error applying target encoder for {col}: {e}")
                        df_encoded[col] = df_encoded[col].fillna(0)
                
                elif encoder_type == 'label':
                    try:
                        # Handle unseen labels
                        known_classes = set(encoder.classes_)
                        df_encoded[col] = df_encoded[col].astype(str).apply(
                            lambda x: x if x in known_classes else encoder.classes_[0]
                        )
                        df_encoded[col] = encoder.transform(df_encoded[col])
                    except Exception as e:
                        logger.warning(f"Error applying label encoder for {col}: {e}")
                        df_encoded[col] = 0  # Default value
    
    return df_encoded

def _advanced_feature_selection(df: pd.DataFrame, y: np.ndarray, 
                               artifacts: Dict, config: Dict[str, Any]) -> pd.DataFrame:
    """Advanced feature selection using multiple methods."""
    logger.info("Applying advanced feature selection...")
    
    # Remove constant features
    constant_features = [col for col in df.columns if df[col].nunique() <= 1]
    if constant_features:
        logger.info(f"Removing {len(constant_features)} constant features")
        df = df.drop(columns=constant_features)
    
    # Remove highly correlated features
    numeric_df = df.select_dtypes(include=[np.number])
    if len(numeric_df.columns) > 1:
        corr_matrix = numeric_df.corr().abs()
        upper_triangle = corr_matrix.where(np.triu(np.ones(corr_matrix.shape), k=1).astype(bool))
        
        high_corr_features = [column for column in upper_triangle.columns if any(upper_triangle[column] > 0.95)]
        if high_corr_features:
            logger.info(f"Removing {len(high_corr_features)} highly correlated features")
            df = df.drop(columns=high_corr_features)
    
    # Statistical feature selection
    if len(df.columns) > 50:
        k_best = min(50, len(df.columns))
        selector = SelectKBest(score_func=f_classif, k=k_best)
        
        X_selected = selector.fit_transform(df, y)
        selected_features = df.columns[selector.get_support()].tolist()
        
        logger.info(f"Selected {len(selected_features)} features using statistical selection")
        
        artifacts['feature_selector'] = selector
        artifacts['selected_features'] = selected_features
        
        return df[selected_features]
    
    artifacts['selected_features'] = df.columns.tolist()
    return df

def _advanced_feature_scaling(df: pd.DataFrame, numeric_features: List[str], 
                            is_training: bool, artifacts: Dict) -> pd.DataFrame:
    """Advanced feature scaling with robust methods."""
    logger.info("Applying advanced feature scaling...")
    
    df_scaled = df.copy()
    
    if is_training:
        # Use RobustScaler for better handling of outliers
        scaler = RobustScaler()
        df_scaled[numeric_features] = scaler.fit_transform(df_scaled[numeric_features])
        artifacts['scaler'] = scaler
    else:
        if 'scaler' in artifacts:
            available_features = [col for col in numeric_features if col in df_scaled.columns]
            if available_features:
                df_scaled[available_features] = artifacts['scaler'].transform(df_scaled[available_features])
    
    return df_scaled

def prepare_centralized_dataset(config: Dict[str, Any]) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray, Dict]:
    """
    Prepare centralized dataset for baseline comparison with comprehensive preprocessing.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        Tuple of (X_train, X_val, X_test, y_train, y_val, y_test, preprocessing_artifacts)
    """
    logger.info("Preparing centralized dataset with advanced preprocessing...")
    
    # Load raw data
    train_transaction, train_identity, test_transaction, test_identity = load_raw_data(config)
    
    # Perform data quality assessment
    qa_assessment = DataQualityAssessment()
    train_quality = qa_assessment.assess_data_quality(train_transaction, 'isFraud')
    
    # Log quality assessment summary
    logger.info("Data Quality Assessment Summary:")
    for recommendation in train_quality.get('recommendations', []):
        logger.info(f"  - {recommendation}")
    
    # Merge transaction and identity data
    train_merged = merge_transaction_identity(train_transaction, train_identity)
    test_merged = merge_transaction_identity(test_transaction, test_identity)
    
    # Advanced preprocessing
    X_train_full, y_train_full, preprocessing_artifacts = advanced_preprocessing_pipeline(
        train_merged, is_training=True, config=config
    )
    
    # Split training data into train and validation
    X_train, X_val, y_train, y_val = train_test_split(
        X_train_full, y_train_full,
        test_size=config['data']['val_size'],
        random_state=config['data']['random_state'],
        stratify=y_train_full
    )
    
    # Preprocess test data
    X_test, y_test, _ = advanced_preprocessing_pipeline(
        test_merged, is_training=False, 
        preprocessing_artifacts=preprocessing_artifacts, 
        config=config
    )
    
    # Handle case where test data doesn't have labels
    if y_test is None:
        y_test = np.zeros(X_test.shape[0])
    
    # Log dataset statistics
    logger.info("Centralized dataset prepared:")
    logger.info(f"  Train: {X_train.shape}, Fraud rate: {y_train.mean():.4f}")
    logger.info(f"  Validation: {X_val.shape}, Fraud rate: {y_val.mean():.4f}")
    logger.info(f"  Test: {X_test.shape}")
    logger.info(f"  Features: {X_train.shape[1]}")
    
    # Save preprocessing artifacts
    preprocessing_artifacts['dataset_stats'] = {
        'train_samples': len(X_train),
        'val_samples': len(X_val),
        'test_samples': len(X_test),
        'features': X_train.shape[1],
        'fraud_rate_train': float(y_train.mean()),
        'fraud_rate_val': float(y_val.mean()),
        'preprocessing_timestamp': datetime.now().isoformat()
    }
    
    return X_train, X_val, X_test, y_train, y_val, y_test, preprocessing_artifacts

def prepare_local_datasets_for_banks(config: Dict[str, Any]) -> Dict[str, Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]]:
    """
    Prepare non-IID datasets for individual banks with advanced partitioning strategies.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        Dictionary mapping bank names to (X_train, X_val, y_train, y_val) tuples
    """
    from .partition_utils import create_noniid_splits
    
    logger.info("Preparing local datasets for banks with advanced partitioning...")
    
    # Load and preprocess centralized data first
    X_train_full, X_val_full, _, y_train_full, y_val_full, _, preprocessing_artifacts = prepare_centralized_dataset(config)
    
    # Combine train and val for partitioning
    X_combined = np.vstack([X_train_full, X_val_full])
    y_combined = np.hstack([y_train_full, y_val_full])
    
    # Create non-IID splits
    bank_data = create_noniid_splits(
        X_combined, y_combined, 
        strategy=config['data']['partition_strategy'],
        num_banks=config['data']['num_banks'],
        random_state=config['data']['random_state']
    )
    
    # Split each bank's data into train/val with stratification
    bank_datasets = {}
    for bank_name, (X_bank, y_bank) in bank_data.items():
        # Ensure we have both classes for stratification
        if len(np.unique(y_bank)) > 1:
            X_train_bank, X_val_bank, y_train_bank, y_val_bank = train_test_split(
                X_bank, y_bank,
                test_size=config['data']['val_size'],
                random_state=config['data']['random_state'],
                stratify=y_bank
            )
        else:
            # If only one class, split without stratification
            split_idx = int(len(X_bank) * (1 - config['data']['val_size']))
            X_train_bank, X_val_bank = X_bank[:split_idx], X_bank[split_idx:]
            y_train_bank, y_val_bank = y_bank[:split_idx], y_bank[split_idx:]
        
        bank_datasets[bank_name] = (X_train_bank, X_val_bank, y_train_bank, y_val_bank)
        
        # Log bank statistics
        fraud_rate_train = y_train_bank.mean()
        fraud_rate_val = y_val_bank.mean() if len(y_val_bank) > 0 else 0
        
        logger.info(f"{bank_name} dataset:")
        logger.info(f"  Train: {X_train_bank.shape}, Fraud rate: {fraud_rate_train:.4f}")
        logger.info(f"  Val: {X_val_bank.shape}, Fraud rate: {fraud_rate_val:.4f}")
    
    # Save bank dataset statistics
    bank_stats = {}
    for bank_name, (X_train, X_val, y_train, y_val) in bank_datasets.items():
        bank_stats[bank_name] = {
            'train_samples': len(X_train),
            'val_samples': len(X_val),
            'fraud_rate_train': float(y_train.mean()),
            'fraud_rate_val': float(y_val.mean()) if len(y_val) > 0 else 0.0,
            'total_samples': len(X_train) + len(X_val)
        }
    
    # Save statistics to file
    os.makedirs('results', exist_ok=True)
    with open('results/bank_dataset_stats.json', 'w') as f:
        json.dump(bank_stats, f, indent=2)
    
    return bank_datasets

def prepare_global_test_set(config: Dict[str, Any]) -> Tuple[np.ndarray, np.ndarray]:
    """
    Prepare global test set for evaluation with consistent preprocessing.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        Tuple of (X_test, y_test)
    """
    logger.info("Preparing global test set...")
    
    # Reuse centralized preprocessing for consistency
    _, _, X_test, _, _, y_test, _ = prepare_centralized_dataset(config)
    
    logger.info(f"Global test set prepared: {X_test.shape}")
    
    return X_test, y_test

def create_advanced_data_loaders(X: np.ndarray, y: np.ndarray, batch_size: int, 
                               shuffle: bool = True, balance_classes: bool = False,
                               augment_minority: bool = False) -> DataLoader:
    """
    Create advanced PyTorch DataLoader with class balancing and augmentation options.
    
    Args:
        X: Feature matrix
        y: Target vector
        batch_size: Batch size for DataLoader
        shuffle: Whether to shuffle data
        balance_classes: Whether to use weighted sampling for class balance
        augment_minority: Whether to augment minority class samples
        
    Returns:
        PyTorch DataLoader with advanced features
    """
    # Calculate sample weights for balanced training
    sample_weights = None
    sampler = None
    
    if balance_classes:
        class_counts = Counter(y.astype(int))
        total_samples = len(y)
        
        # Calculate weights inversely proportional to class frequency
        class_weights = {cls: total_samples / (len(class_counts) * count) 
                        for cls, count in class_counts.items()}
        
        sample_weights = np.array([class_weights[int(label)] for label in y])
        
        # Create weighted sampler
        sampler = WeightedRandomSampler(
            weights=sample_weights,
            num_samples=len(sample_weights),
            replacement=True
        )
        shuffle = False  # Sampler handles shuffling
    
    # Create dataset
    dataset = AdvancedFraudDataset(
        X, y, 
        sample_weights=sample_weights,
        augment_minority=augment_minority
    )
    
    # Create data loader
    loader = DataLoader(
        dataset, 
        batch_size=batch_size, 
        shuffle=shuffle,
        sampler=sampler,
        num_workers=0,  # Set to 0 for Windows compatibility
        pin_memory=torch.cuda.is_available(),
        drop_last=False
    )
    
    return loader

# Alias for backward compatibility
create_data_loaders = create_advanced_data_loaders

def save_preprocessing_artifacts(artifacts: Dict[str, Any], filepath: str) -> None:
    """
    Save preprocessing artifacts with comprehensive metadata.
    
    Args:
        artifacts: Dictionary containing preprocessing artifacts
        filepath: Path to save the artifacts
    """
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    # Add metadata
    artifacts['metadata'] = {
        'save_timestamp': datetime.now().isoformat(),
        'artifact_types': list(artifacts.keys()),
        'python_version': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
        'sklearn_version': sklearn.__version__ if 'sklearn' in sys.modules else 'unknown'
    }
    
    # Save artifacts
    with open(filepath, 'wb') as f:
        pickle.dump(artifacts, f, protocol=pickle.HIGHEST_PROTOCOL)
    
    logger.info(f"Preprocessing artifacts saved to: {filepath}")

def load_preprocessing_artifacts(filepath: str) -> Dict[str, Any]:
    """
    Load preprocessing artifacts with validation.
    
    Args:
        filepath: Path to load the artifacts from
        
    Returns:
        Dictionary containing preprocessing artifacts
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Preprocessing artifacts not found: {filepath}")
    
    with open(filepath, 'rb') as f:
        artifacts = pickle.load(f)
    
    logger.info(f"Preprocessing artifacts loaded from: {filepath}")
    
    # Log metadata if available
    if 'metadata' in artifacts:
        metadata = artifacts['metadata']
        logger.info(f"  Saved: {metadata.get('save_timestamp', 'unknown')}")
        logger.info(f"  Artifact types: {len(metadata.get('artifact_types', []))}")
    
    return artifacts

def get_feature_importance_names(preprocessing_artifacts: Dict[str, Any]) -> List[str]:
    """
    Get feature names for interpretability from preprocessing artifacts.
    
    Args:
        preprocessing_artifacts: Preprocessing artifacts containing feature names
        
    Returns:
        List of feature names
    """
    if 'feature_names' in preprocessing_artifacts:
        return preprocessing_artifacts['feature_names']
    
    # Fallback to generic names
    feature_count = preprocessing_artifacts.get('feature_count', 100)
    return [f'feature_{i}' for i in range(feature_count)]

def monitor_memory_usage() -> Dict[str, float]:
    """
    Monitor current memory usage for optimization.
    
    Returns:
        Dictionary containing memory usage statistics
    """
    process = psutil.Process()
    memory_info = process.memory_info()
    
    return {
        'rss_mb': memory_info.rss / 1024**2,  # Resident Set Size
        'vms_mb': memory_info.vms / 1024**2,  # Virtual Memory Size
        'percent': process.memory_percent(),
        'available_mb': psutil.virtual_memory().available / 1024**2
    }

def optimize_memory_usage():
    """Optimize memory usage by forcing garbage collection."""
    gc.collect()
    if torch.cuda.is_available():
        torch.cuda.empty_cache()

# Export main functions
__all__ = [
    'load_config',
    'load_raw_data', 
    'merge_transaction_identity',
    'advanced_preprocessing_pipeline',
    'prepare_centralized_dataset',
    'prepare_local_datasets_for_banks', 
    'prepare_global_test_set',
    'create_advanced_data_loaders',
    'create_data_loaders',
    'AdvancedFraudDataset',
    'DataQualityAssessment',
    'AdvancedFeatureEngineering',
    'save_preprocessing_artifacts',
    'load_preprocessing_artifacts',
    'get_feature_importance_names',
    'monitor_memory_usage',
    'optimize_memory_usage'
]