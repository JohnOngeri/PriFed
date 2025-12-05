import pandas as pd
import numpy as np

def analyze_dataset():
    # Load datasets
    print("Loading datasets...")
    train_trans = pd.read_csv('dataset/train_transaction.csv')
    train_identity = pd.read_csv('dataset/train_identity.csv')
    test_trans = pd.read_csv('dataset/test_transaction.csv')
    test_identity = pd.read_csv('dataset/test_identity.csv')
    
    print("=== DATASET OVERVIEW ===")
    print(f"Train Transaction: {train_trans.shape}")
    print(f"Train Identity: {train_identity.shape}")
    print(f"Test Transaction: {test_trans.shape}")
    print(f"Test Identity: {test_identity.shape}")
    
    print("\n=== TRAIN TRANSACTION ANALYSIS ===")
    print("Columns:", list(train_trans.columns[:10]), "... (showing first 10)")
    print("Missing values:", train_trans.isnull().sum().sum())
    if 'isFraud' in train_trans.columns:
        print("Fraud distribution:", train_trans['isFraud'].value_counts())
        print("Fraud rate:", train_trans['isFraud'].mean())
    
    print("\n=== TRAIN IDENTITY ANALYSIS ===")
    print("Columns:", list(train_identity.columns[:10]), "... (showing first 10)")
    print("Missing values:", train_identity.isnull().sum().sum())
    
    print("\n=== KEY STATISTICS ===")
    print("Transaction amount stats:")
    if 'TransactionAmt' in train_trans.columns:
        print(train_trans['TransactionAmt'].describe())
    
    print("\n=== DATA TYPES ===")
    print("Transaction data types:")
    print(train_trans.dtypes.value_counts())

if __name__ == "__main__":
    analyze_dataset()