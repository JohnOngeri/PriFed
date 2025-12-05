# PrivFed Backend

Privacy-Preserving Federated Learning for Fraud Detection - Backend Implementation

## Setup

1. Create virtual environment:
```bash
python -m venv venv
venv\Scripts\activate  # Windows
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure dataset path in `configs/config.yaml`

## Usage

### Run Centralized Baseline
```bash
python scripts/run_centralized_baseline.py
```

### Run Federated Learning
```bash
python scripts/run_federated_training.py
```

### Run Federated Learning with DP
```bash
python scripts/run_federated_dp_training.py --epsilon 8.0
```

### Start API Server
```bash
python -m api.main
```

## API Endpoints

- `GET /api/status` - System status
- `GET /api/metrics/global` - Global metrics
- `GET /api/metrics/banks` - Bank metrics
- `GET /api/privacy` - Privacy metrics
- `POST /api/fraud/predict` - Fraud prediction

## Configuration

Edit `configs/config.yaml` to modify:
- Dataset paths
- Model parameters
- FL settings
- DP parameters

## Results

Training results are saved in:
- `results/` - Metrics and plots
- `models/` - Trained models
- `logs/` - Training logs