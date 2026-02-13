# PrivFed: Privacy-Preserving Federated Learning for Fraud Detection

This is a machine learning system designed to detect fraud across multiple banking institutions without sharing raw transaction data. The system utilizes Federated Learning (FedAvg) and Differential Privacy (DP) to maintain data sovereignty while improving collective detection accuracy.

## Problem Statement

Multiple banks worldwide want to collaborate to detect fraudulent transactions more effectively, but face critical challenges:

- **Privacy Constraints**: Cannot share raw customer data due to regulations (GDPR, PCI-DSS) and competitive concerns
- **Data Heterogeneity**: Each bank has different customer demographics, fraud patterns, and transaction distributions (non-IID data)
- **Security Risks**: Even federated learning can leak information through model updates (membership inference, model inversion attacks)

**[View Demo](https://drive.google.com/file/d/1yrd_p3grg8ILx5N4GycSr1ZawXh-0fQb/view?usp=sharing)**

---

## Solution Architecture

PrivFed implements a sophisticated three-layer privacy-preserving system:

1. **Federated Learning Layer**: Banks train locally and share only model updates
2. **Differential Privacy Layer**: Adds calibrated noise to prevent information leakage
3. **Fairness Monitoring Layer**: Ensures equitable performance across all participating banks

### Data Engineering and Visualization

The system processes the IEEE-CIS Fraud Detection dataset through a multi-stage pipeline:

- **Engineering**: Includes log transformations of transaction amounts, temporal extraction (hour, day, week), and card interaction ratios
- **Partitioning**: Data is split into non-IID (non-independent and identically distributed) sets to simulate realistic differences between commercial, premium, and regional banks
- **Visualizations**: The notebook generates distributions of transaction sizes and fraud rates per bank to demonstrate data heterogeneity

### Model Architecture

The core model is an optimized Multi-Layer Perceptron (MLP) designed for tabular data:

| Component | Details |
|-----------|---------|
| **Input Layer** | Configurable based on engineered feature count (~432 features) |
| **Hidden Layers** | Three fully connected layers with 256, 128, and 64 units respectively |
| **Activation** | ReLU functions for non-linear pattern handling |
| **Regularization** | Batch Normalization and 0.3 Dropout rate to prevent overfitting |
| **Optimizer** | Adam optimizer with learning rate 0.001 and weight decay 1e-5 |

### Performance Metrics

The model is evaluated using metrics critical for imbalanced fraud datasets:

- **AUC-ROC**: Primary metric for classification quality across decision thresholds
- **PR-AUC**: Precision-recall balance, essential for detecting rare fraud events
- **Recall**: System's ability to capture the maximum number of fraudulent transactions

**Initial Results**: Empirical evidence shows the federated model achieves higher AUC than banks training in isolation, proving collaboration gain.

### Development Stack

- **Backend**: Python with PyTorch for deep learning and Flower (flwr) for federated framework
- **Privacy**: Opacus library implements DP-SGD (Differential Privacy Stochastic Gradient Descent)
- **Configuration**: All hyperparameters and strategies managed via central `config.yaml`

---
# 1. REPOSITORY AND WORKSPACE SETUP
# Clone the source code into your working environment
git clone https://github.com/JohnOngeri/PriFed.git
cd PriFed/backend

# Ensure your python path includes the backend directory to resolve internal modules
export PYTHONPATH=$PYTHONPATH:$(pwd)

# 2. INSTALL CORE DEPENDENCIES
# Install the specific scientific stack and deep learning frameworks
pip install -q torch torchvision torchaudio numpy pandas scikit-learn pyyaml matplotlib seaborn

# Install the Federated Learning framework with simulation capabilities
pip install -q "flwr[simulation]>=1.5.0"

# Install Opacus for Differential Privacy and fix Protobuf versioning
pip install -q opacus==1.3.0
pip install --force-reinstall protobuf==5.28.0

# 3. DATA CONFIGURATION
# Create the dataset directory and place your IEEE-CIS CSV files inside
mkdir -p ../dataset
# (Move your train_transaction.csv, train_identity.csv, etc., into ../dataset)

# 4. SYSTEM PARAMETERS (configs/config.yaml)
# Open and update the following key sections in your configuration file:
# - data: Set dataset_path to the absolute path of your dataset folder
# - model: Define architecture layers (e.g., [256, 128, 64]) and dropout rate
# - differential_privacy: Set noise_multiplier and target_delta for ε budget
# - federated_learning: Define num_rounds and strategy (FedAvg/FedProx)

# 5. EXECUTION AND PERSISTENCE
# Start the training process from your notebook or main script
# The system will automatically:
# - Partition data into non-IID bank sets
# - Initialize model checkpoints in the 'checkpoints' folder
# - Log metrics to 'results/training_logs.csv' for analysis
