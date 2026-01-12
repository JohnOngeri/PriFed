# Google Colab Training Guide

## Overview
This guide explains how to train your federated learning models in Google Colab and transfer them back to your local project.

---

## 📋 **Approach 1: Complete Training in Colab (Recommended)**

### **Step 1: Prepare Your Code for Colab**

#### **Option A: Upload Code Files**
1. Zip your `backend/utils/` directory
2. Upload to Colab using:
   ```python
   from google.colab import files
   uploaded = files.upload()  # Upload your zip file
   !unzip your_utils.zip
   ```

#### **Option B: Clone from GitHub (Best)**
```python
# In Colab cell
!git clone https://github.com/yourusername/PriFed.git
%cd PriFed/backend
```

#### **Option C: Copy Code Directly**
Copy essential files into Colab cells:
- `utils/model_utils.py`
- `utils/fl_utils.py`
- `utils/data_utils.py`
- `utils/metrics_utils.py`
- `utils/dp_utils.py`

---

### **Step 2: Upload Dataset**

```python
from google.colab import files
import os

# Create dataset directory
os.makedirs('dataset', exist_ok=True)

# Upload files (run this cell multiple times for each file)
uploaded = files.upload()

# Move files to dataset folder
for filename in uploaded.keys():
    os.rename(filename, f'dataset/{filename}')
```

**Or use Google Drive:**
```python
from google.colab import drive
drive.mount('/content/drive')

# Copy dataset from Drive
!cp -r /content/drive/MyDrive/PriFed/dataset ./dataset
```

---

### **Step 3: Install Dependencies**

```python
!pip install torch torchvision torchaudio
!pip install flwr
!pip install numpy pandas scikit-learn
!pip install pyyaml
!pip install matplotlib seaborn
```

---

### **Step 4: Create Colab Training Script**

```python
# ============================================
# Colab Federated Training Script
# ============================================

import sys
import os
sys.path.append('/content/PriFed/backend')  # Adjust path

import torch
import numpy as np
import json
from datetime import datetime
from utils.data_utils import load_config, prepare_local_datasets_for_banks, prepare_global_test_set
from utils.fl_utils import run_federated_training, save_federated_results
from utils.model_utils import save_model
from utils.metrics_utils import MetricsTracker

# Configuration (adjust as needed)
config = {
    'data': {
        'dataset_path': './dataset',
        'train_transaction': 'train_transaction.csv',
        'train_identity': 'train_identity.csv',
        'test_transaction': 'test_transaction.csv',
        'test_identity': 'test_identity.csv',
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
        'device': 'cuda' if torch.cuda.is_available() else 'cpu',
        'save_checkpoints': True,
        'checkpoint_frequency': 10
    }
}

# Create output directories
os.makedirs('models', exist_ok=True)
os.makedirs('results', exist_ok=True)
os.makedirs('logs', exist_ok=True)

print("Starting federated training in Colab...")
print(f"Using device: {config['experiment']['device']}")

# Prepare data
print("Preparing datasets...")
bank_datasets = prepare_local_datasets_for_banks(config)
X_test, y_test = prepare_global_test_set(config)

print(f"Number of banks: {len(bank_datasets)}")
print(f"Test set size: {X_test.shape[0]}")

# Run federated training
print("Running federated training...")
results = run_federated_training(config, bank_datasets, (X_test, y_test))

# Save results
results_file = f"results/federated_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
save_federated_results(results, results_file)

print(f"Training completed! Results saved to: {results_file}")
print(f"Number of rounds: {results.get('num_rounds', 'N/A')}")
```

---

### **Step 5: Save Models for Download**

```python
# Save final global model
from utils.model_utils import save_model

# Extract final model from results (adjust based on your fl_utils implementation)
# This is a placeholder - adjust based on your actual results structure
final_model = results.get('final_model')  # Adjust this based on your implementation

if final_model is not None:
    model_path = f"models/global_model_final_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pth"
    save_model(
        final_model,
        model_path,
        metadata={
            'training_date': datetime.now().isoformat(),
            'num_rounds': results.get('num_rounds'),
            'config': config
        }
    )
    print(f"Model saved to: {model_path}")
```

---

### **Step 6: Download Models and Results**

```python
# Download models
from google.colab import files

# Download all model files
import glob
model_files = glob.glob('models/*.pth')
for model_file in model_files:
    files.download(model_file)

# Download results
result_files = glob.glob('results/*.json')
for result_file in result_files:
    files.download(result_file)

# Or download entire directories as zip
!zip -r models.zip models/
!zip -r results.zip results/
files.download('models.zip')
files.download('results.zip')
```

**Or save to Google Drive:**
```python
# Save to Drive
!cp -r models /content/drive/MyDrive/PriFed/backend/
!cp -r results /content/drive/MyDrive/PriFed/backend/
```

---

## 📋 **Approach 2: Hybrid Approach (Train in Colab, Integrate Locally)**

### **Step 1: Train in Colab** (Follow Steps 1-5 above)

### **Step 2: Transfer Models to Local Project**

```bash
# On your local machine
cd C:\PriFed\backend

# Create models directory if it doesn't exist
mkdir -p models

# Copy downloaded models here
# Or if using Drive:
# Copy from Google Drive to backend/models/
```

### **Step 3: Load Models in Local Backend**

```python
# In your local backend/api/services.py or similar
from utils.model_utils import load_model
import os

def load_trained_model():
    """Load the model trained in Colab."""
    model_path = 'models/global_model_final_YYYYMMDD_HHMMSS.pth'  # Update with actual filename
    
    if os.path.exists(model_path):
        model, metadata = load_model(model_path)
        print(f"Model loaded successfully!")
        print(f"Training date: {metadata.get('training_date', 'N/A')}")
        return model, metadata
    else:
        print(f"Model file not found: {model_path}")
        return None, {}
```

---

## 📋 **Approach 3: Use Colab Notebook Template**

Create a complete Colab notebook that:
1. Sets up environment
2. Downloads/clones your code
3. Trains models
4. Saves everything properly
5. Provides download links

---

## 🔧 **Best Practices**

### **1. Model Serialization**
- Always save with metadata (config, training date, metrics)
- Use the `save_model()` function from `model_utils.py`
- Include model architecture info for proper loading

### **2. Version Control**
- Tag your models with timestamps
- Save config files alongside models
- Document hyperparameters and results

### **3. File Organization**
```
models/
  ├── global_model_final_20240112_143022.pth
  ├── global_model_checkpoint_round_10.pth
  └── metadata.json

results/
  ├── federated_results_20240112_143022.json
  ├── round_metrics.json
  └── training_history.json
```

### **4. Integration Checklist**
- [ ] Models saved with proper metadata
- [ ] Config files match between Colab and local
- [ ] Model architecture is compatible
- [ ] Input dimensions match
- [ ] Dependencies are installed locally
- [ ] Test model loading before deployment

---

## 🚀 **Quick Start Colab Notebook**

See `backend/colab_training_notebook.ipynb` for a ready-to-use notebook template.

---

## ⚠️ **Important Notes**

1. **Colab Session Limits**: Free Colab sessions timeout after ~12 hours. Save frequently!
2. **GPU Availability**: Colab provides free GPU but with usage limits
3. **File Size**: Colab has storage limits. Use Drive for large datasets
4. **Model Compatibility**: Ensure PyTorch versions match between Colab and local
5. **Path Differences**: Adjust file paths for Colab vs local environments

---

## 📝 **Example: Complete Colab Workflow**

```python
# Cell 1: Setup
!git clone https://github.com/yourusername/PriFed.git
%cd PriFed/backend
!pip install -r requirements.txt

# Cell 2: Upload Data
from google.colab import files
uploaded = files.upload()

# Cell 3: Train
# (Use training script from Step 4 above)

# Cell 4: Save & Download
# (Use download script from Step 6 above)
```

---

## 🔗 **Integration with Local Backend**

After downloading models:

1. Place models in `backend/models/`
2. Update API services to load models:
   ```python
   # backend/api/services.py
   model, metadata = load_model('models/global_model_final_XXX.pth')
   ```
3. Test model inference locally
4. Sync training results to database using `sync_training_to_db.py`

---

## 📚 **Additional Resources**

- [Flower Documentation](https://flower.dev/)
- [PyTorch Model Saving](https://pytorch.org/tutorials/beginner/saving_loading_models.html)
- [Google Colab Tips](https://colab.research.google.com/notebooks/basic_features_overview.ipynb)
