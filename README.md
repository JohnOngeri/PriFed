# PrivFed: Privacy-Preserving Federated Learning for Fraud Detection

This is a machine learning system designed to detect fraud across multiple banking institutions without sharing raw transaction data. The system utilizes Federated Learning (FedAvg) and Differential Privacy (DP) to maintain data sovereignty while improving collective detection accuracy.

**Problem Statement**
Multiple banks worldwide want to collaborate to detect fraudulent transactions more effectively, but face critical challenges:
- **Privacy Constraints**: Cannot share raw customer data due to regulations (GDPR, PCI-DSS) and competitive concerns
- **Data Heterogeneity**: Each bank has different customer demographics, fraud patterns, and transaction distributions (non-IID data)
- **Security Risks**: Even federated learning can leak information through model updates (membership inference, model inversion attacks)

Initial software product/solution demonstration:  [ https://drive.google.com/file/d/1yrd_p3grg8ILx5N4GycSr1ZawXh-0fQb/view?usp=sharing
](url)
**Solution Architecture**
PrivFed implements a sophisticated three-layer privacy-preserving system:

1. **Federated Learning Layer**: Banks train locally and share only model updates
2. **Differential Privacy Layer**: Adds calibrated noise to prevent information leakage
3. **Fairness Monitoring Layer**: Ensures equitable performance across all participating banks

**Data Engineering and Visualization**
The system processes the IEEE-CIS Fraud Detection dataset through a multi-stage pipeline:

Engineering: Includes log transformations of transaction amounts, temporal extraction (hour, day, week), and card interaction ratios.

**Partitioning**: Data is split into non-IID (non-independent and identically distributed) sets to simulate realistic differences between commercial, premium, and regional banks.

**Visualizations:** The notebook generates distributions of transaction sizes and fraud rates per bank to demonstrate data heterogeneity.
**
**Model Architecture****
The core model is an optimized Multi-Layer Perceptron (MLP) designed for tabular data:

Input Layer: Configurable based on engineered feature count, supporting approximately 432 features.

Hidden Layers: Three fully connected layers with 256, 128, and 64 units respectively.

Activation: ReLU functions are used throughout the hidden layers to handle non-linear patterns in transaction behavior.

Regularization: Incorporates Batch Normalization and a 0.3 Dropout rate to prevent overfitting on local bank data.

Optimizer: Training utilizes the Adam optimizer with a learning rate of 0.001 and weight decay of 1e-5.

**Performance Metrics**
The model is evaluated using metrics critical for imbalanced fraud datasets:

AUC-ROC: The primary metric used to determine classification quality across various decision thresholds.

PR-AUC: Measures the precision-recall balance, which is essential for detecting rare fraud events in heavily skewed data.

Recall: Focuses on the system's ability to capture the maximum number of fraudulent transactions possible.

Initial Results: Empirical evidence shows the federated model achieves higher AUC than banks training in isolation, proving a collaboration gain.

**Development Environment Setup**
The project uses a modular structure to ensure reproducible results across different environments:

Backend: Python environment leveraging PyTorch for deep learning and Flower (flwr) for the federated framework.

Privacy: The Opacus library implements DP-SGD (Differential Privacy Stochastic Gradient Descent) to add calibrated noise to model updates.

Configuration: All hyperparameters, partition strategies, and data paths are managed via a central config.yaml file.



**Deployment Option (Mockup)**
The system is designed to be exposed via a REST API for real-time fraud scoring.

**API Interface (Swagger UI Mockup)**
POST /predict: Accepts transaction features and returns a fraud probability score.

GET /privacy-status: Returns the current privacy budget (epsilon) used during training.

GET /metrics: Provides the latest global accuracy and fairness stats across the federation.

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    PrivFed System Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│   Mobile Frontend (Flutter)                                   │
│  ├── Splash & Onboarding Screens                               │
│  ├── Real-time Training Dashboard                              │
│  ├── Privacy Monitoring Interface                              │
│  ├── Bank Performance Comparison                               │
│  └── Fraud Detection Explorer                                  │
├─────────────────────────────────────────────────────────────────┤
│   REST API Layer (FastAPI)                                   │
│  ├── /api/status - System status                               │
│  ├── /api/metrics/* - Training metrics                         │
│  ├── /api/privacy - Privacy accounting                         │
│  └── /api/fraud/predict - Real-time prediction                 │
├─────────────────────────────────────────────────────────────────┤
│   Federated Learning Engine (Flower + PyTorch)              │
│  ├── FedAvg Strategy with Non-IID optimization                 │
│  ├── DP-SGD Integration (Opacus)                              │
│  ├── Privacy Accounting (RDP/GDP)                             │
│  └── Fairness Monitoring                                       │
├─────────────────────────────────────────────────────────────────┤
│   Simulated Banks (Non-IID Data Partitioning)               │
│  ├── Bank A: Early-period transactions                         │
│  ├── Bank B: Mid-period transactions                           │
│  └── Bank C: Late-period transactions                          │
├─────────────────────────────────────────────────────────────────┤
│   IEEE-CIS Fraud Detection Dataset                           │
│  ├── 590,540 training transactions                             │
│  ├── 506,691 test transactions                                 │
│  ├── 433 transaction features                                  │
│  └── 40 identity features                                      │
└─────────────────────────────────────────────────────────────────┘
```


## 📁 Project Structure

```
PrivFed/
├── backend/                    # Python backend with FastAPI
│   ├── api/                   # REST API endpoints
│   ├── utils/                 # Core ML and FL utilities
│   ├── scripts/               # Training and evaluation scripts
│   ├── tests/                 # Comprehensive test suite
│   ├── configs/               # Configuration management
│   ├── models/                # Saved model artifacts
│   ├── results/               # Training results and visualizations
│   └── logs/                  # Detailed logging and privacy accounting
├── frontend/                   # Flutter mobile application
│   └── mobile_app/
│       ├── lib/               # Dart source code
│       ├── assets/            # Images, animations, videos
│       └── components/        # Reusable UI components
├── docs/                      # Comprehensive documentation
├── visual_assets/             # AI-generated visual content prompts
└── dataset/                   # IEEE-CIS fraud detection data
```



## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- Flutter 3.10+
- Git
- 8GB+ RAM
- CUDA-capable GPU (optional, for faster training)

### Backend Setup
```bash
# Clone repository
git clone <repository-url>
cd PrivFed/backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Configure dataset path
# Edit configs/config.yaml to point to your dataset location

# Run centralized baseline
python scripts/run_centralized_baseline.py

# Run federated learning
python scripts/run_federated_training.py

# Run federated learning with differential privacy
python scripts/run_federated_dp_training.py --epsilon 8.0

# Start API server
uvicorn api.main:app --reload
```

### Frontend Setup
```bash
cd ../frontend/mobile_app

# Install Flutter dependencies
flutter pub get

# Run on emulator/device
flutter run

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

