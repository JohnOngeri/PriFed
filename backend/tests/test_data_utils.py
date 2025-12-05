"""
Tests for data utilities.
"""

import pytest
import numpy as np
import pandas as pd
import tempfile
import os
from unittest.mock import patch, MagicMock

import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.data_utils import preprocess_features, create_data_loaders, FraudDataset

def test_fraud_dataset():
    """Test FraudDataset class."""
    X = np.random.randn(100, 10)
    y = np.random.randint(0, 2, 100)
    
    dataset = FraudDataset(X, y)
    
    assert len(dataset) == 100
    x_sample, y_sample = dataset[0]
    assert x_sample.shape == (10,)
    assert y_sample.shape == ()

def test_preprocess_features():
    """Test feature preprocessing."""
    # Create sample data
    data = {
        'TransactionID': [1, 2, 3, 4, 5],
        'isFraud': [0, 1, 0, 1, 0],
        'TransactionAmt': [100.0, 200.0, 150.0, 300.0, 50.0],
        'ProductCD': ['W', 'C', 'W', 'H', 'W'],
        'card1': [1234, 5678, 9012, 3456, 7890],
        'C1': [1, 2, 1, 3, 2]
    }
    df = pd.DataFrame(data)
    
    X, y, scalers, encoders = preprocess_features(df, is_training=True)
    
    assert X is not None
    assert y is not None
    assert len(y) == 5
    assert X.shape[0] == 5
    assert scalers is not None
    assert encoders is not None

def test_create_data_loaders():
    """Test data loader creation."""
    X = np.random.randn(100, 10)
    y = np.random.randint(0, 2, 100)
    
    loader = create_data_loaders(X, y, batch_size=32, shuffle=True)
    
    assert loader is not None
    batch_X, batch_y = next(iter(loader))
    assert batch_X.shape[1] == 10
    assert len(batch_y) <= 32