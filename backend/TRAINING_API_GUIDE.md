# Training Results API Integration Guide

## ✅ **API Endpoint Created!**

I've created a REST API endpoint that Python training scripts can call directly to store training results in the database. **No Prisma Python client needed!**

---

## 🚀 **Quick Start**

### **Step 1: Start Node.js Backend**

```bash
cd backend
npm install
npm run db:generate
npm run db:migrate
npm run dev
```

**Verify API is running:**
```bash
curl http://localhost:8000/api/health
```

### **Step 2: Train Models**

```bash
cd backend
pip install -r requirements.txt
python scripts/run_federated_training.py
```

This will create `results/federated_results.json` with training results.

### **Step 3: Sync Results to Database**

```bash
# Install requests (if not already installed)
pip install requests

# Sync training results via API
python scripts/sync_training_to_api.py --results results/federated_results.json
```

**That's it!** Training results are now in the database and accessible via the Flutter app.

---

## 📡 **API Endpoints**

### **1. Store Single Training Round**

**Endpoint:** `POST /api/training/rounds`

**Request Body:**
```json
{
  "round": 1,
  "global_metrics": {
    "auc": 0.962,
    "accuracy": 0.948,
    "precision": 0.943,
    "recall": 0.950,
    "f1": 0.946,
    "loss": 0.123,
    "specificity": 0.945
  },
  "client_metrics": {
    "bank_a": {
      "auc": 0.958,
      "accuracy": 0.942,
      "precision": 0.938,
      "recall": 0.945,
      "f1": 0.941,
      "loss": 0.125,
      "num_samples": 45231,
      "fraud_rate": 0.032
    },
    "bank_b": {
      "auc": 0.963,
      "accuracy": 0.948,
      "precision": 0.944,
      "recall": 0.951,
      "f1": 0.947,
      "loss": 0.121,
      "num_samples": 38947,
      "fraud_rate": 0.028
    }
  },
  "privacy_metrics": {
    "current_epsilon": 7.8,
    "target_epsilon": 8.0,
    "delta": 1e-5,
    "noise_multiplier": 1.1,
    "privacy_strength": "Strong",
    "budget_used_percentage": 85.2
  },
  "timestamp": "2024-01-15T10:30:00Z",
  "duration": 123.45
}
```

**Response:**
```json
{
  "message": "Training round stored successfully",
  "round": 1,
  "training_round_id": "uuid-here",
  "banks_synced": ["bank_a", "bank_b"],
  "banks_count": 2,
  "has_privacy_metrics": true,
  "timestamp": "2024-01-15T10:30:05Z"
}
```

**Example (Python):**
```python
import requests

round_data = {
    "round": 1,
    "global_metrics": {...},
    "client_metrics": {...},
    "privacy_metrics": {...}
}

response = requests.post(
    "http://localhost:8000/api/training/rounds",
    json=round_data
)

if response.status_code == 201:
    print("Round stored successfully!")
```

---

### **2. Store Multiple Training Rounds (Batch)**

**Endpoint:** `POST /api/training/rounds/batch`

**Request Body:** Array of training rounds
```json
[
  {
    "round": 1,
    "global_metrics": {...},
    "client_metrics": {...}
  },
  {
    "round": 2,
    "global_metrics": {...},
    "client_metrics": {...}
  }
]
```

**Response:**
```json
{
  "message": "Batch training rounds processed",
  "total": 50,
  "successful": 48,
  "failed": 0,
  "skipped": 2,
  "results": {
    "successful": [...],
    "failed": [...],
    "skipped": [...]
  }
}
```

**Example (Python):**
```python
import requests

rounds = [
    {"round": 1, "global_metrics": {...}, ...},
    {"round": 2, "global_metrics": {...}, ...},
    # ... more rounds
]

response = requests.post(
    "http://localhost:8000/api/training/rounds/batch",
    json=rounds
)
```

---

### **3. Sync Complete Training Results**

**Endpoint:** `POST /api/training/sync`

**Request Body:**
```json
{
  "results": {
    "history": [
      {"round": 1, "global_metrics": {...}, ...},
      {"round": 2, "global_metrics": {...}, ...}
    ]
  }
}
```

**Response:** Same as batch endpoint

---

## 🐍 **Python Script Usage**

### **Option 1: Use the Sync Script (Recommended)**

```bash
# Basic usage
python scripts/sync_training_to_api.py --results results/federated_results.json

# Custom API URL
python scripts/sync_training_to_api.py --results results/federated_results.json --api-url http://localhost:8000

# Use batch mode (faster for many rounds)
python scripts/sync_training_to_api.py --results results/federated_results.json --batch --batch-size 10

# Dry run (see what would be synced)
python scripts/sync_training_to_api.py --results results/federated_results.json --dry-run
```

### **Option 2: Call API Directly from Training Script**

Modify your training script to call the API after each round:

```python
# In your training script
import requests

def store_round_to_api(round_data, api_url="http://localhost:8000"):
    """Store a training round to the Node.js API"""
    try:
        payload = {
            "round": round_data['round'],
            "global_metrics": round_data['metrics'],
            "client_metrics": round_data.get('bank_metrics', {}),
            "privacy_metrics": round_data.get('privacy_metrics'),
            "timestamp": round_data.get('timestamp'),
            "duration": round_data.get('duration')
        }
        
        response = requests.post(
            f"{api_url}/api/training/rounds",
            json=payload,
            timeout=30
        )
        
        if response.status_code == 201:
            print(f"✅ Round {round_data['round']} stored in database")
            return True
        elif response.status_code == 409:
            print(f"⏭️  Round {round_data['round']} already exists")
            return True
        else:
            print(f"❌ Failed to store round {round_data['round']}: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error storing round: {str(e)}")
        return False

# After training completes
results = run_federated_training(config, bank_datasets, test_data)

# Store all rounds
for round_data in results['history']:
    store_round_to_api(round_data)
```

### **Option 3: Store All Rounds After Training**

```python
# After training completes
import requests

results = run_federated_training(config, bank_datasets, test_data)

# Store all rounds at once (batch)
response = requests.post(
    "http://localhost:8000/api/training/rounds/batch",
    json=results['history'],
    timeout=120
)

if response.status_code == 201:
    result = response.json()
    print(f"✅ Synced {result['successful']} rounds to database")
```

---

## ✅ **Verify Integration**

After syncing, verify the data is accessible:

```bash
# Check global metrics
curl http://localhost:8000/api/metrics/global

# Check bank metrics
curl http://localhost:8000/api/metrics/banks

# Check training rounds
curl http://localhost:8000/api/rounds?limit=10

# Check privacy metrics
curl http://localhost:8000/api/privacy
```

**Expected:** All endpoints should now return real training data instead of empty/default values.

---

## 🔒 **Security Notes**

**Current Implementation:**
- Endpoints are publicly accessible (no authentication required)
- This is fine for local development

**For Production:**
1. **Add API Key Authentication:**
   ```javascript
   // In training.routes.js
   const apiKeyAuth = (req, res, next) => {
     const apiKey = req.headers['x-api-key'];
     if (apiKey !== process.env.TRAINING_API_KEY) {
       return res.status(401).json({ error: 'Unauthorized' });
     }
     next();
   };
   
   router.post('/rounds', apiKeyAuth, ...);
   ```

2. **Or Use JWT Authentication:**
   - Generate a service account token for Python scripts
   - Send token in `Authorization: Bearer <token>` header

---

## 🐛 **Troubleshooting**

### **API Not Available**
```
ERROR: Cannot connect to API at http://localhost:8000
```

**Solution:**
1. Make sure Node.js backend is running: `npm run dev`
2. Check if port 8000 is available
3. Verify API health: `curl http://localhost:8000/api/health`

### **Bank Not Found**
```
WARNING: Bank bank_a not found in database, skipping bank metrics
```

**Solution:**
1. Create banks first using the bank management API
2. Or seed the database with default banks

### **Round Already Exists**
```
Round 1 already exists, skipping
```

**Solution:**
- This is normal if you're re-syncing
- Delete existing rounds if you want to re-sync: `DELETE FROM training_rounds WHERE round_number = 1`

### **Validation Error**
```
Validation Error: Invalid request data
```

**Solution:**
- Check that all required fields are present
- Verify metrics are numbers (not strings)
- Ensure round number is a positive integer

---

## 📊 **Data Flow**

```
Python Training Script
    ↓ (trains models)
    ↓ (saves results to JSON)
    ↓
sync_training_to_api.py
    ↓ (reads JSON)
    ↓ (transforms data)
    ↓ (calls REST API)
    ↓
Node.js Backend API
    ↓ (validates data)
    ↓ (stores in PostgreSQL)
    ↓
Flutter App
    ↓ (queries API)
    ↓ (displays results)
```

---

## ✅ **Benefits of This Approach**

1. ✅ **No Prisma Python Client** - Uses standard HTTP requests
2. ✅ **Language Agnostic** - Any language can call the API
3. ✅ **Simple Integration** - Just add API calls to training scripts
4. ✅ **Error Handling** - API validates data before storing
5. ✅ **Batch Support** - Efficient for large datasets
6. ✅ **Idempotent** - Re-running sync is safe (skips duplicates)

---

## 🎯 **Next Steps**

1. ✅ **Test the API endpoint:**
   ```bash
   curl -X POST http://localhost:8000/api/training/rounds \
     -H "Content-Type: application/json" \
     -d @test_round.json
   ```

2. ✅ **Train models and sync:**
   ```bash
   python scripts/run_federated_training.py
   python scripts/sync_training_to_api.py --results results/federated_results.json
   ```

3. ✅ **Verify Flutter app displays data:**
   - Start Flutter app
   - Navigate to metrics screens
   - Should now show real training data!

---

**That's it!** Training results can now be stored in the database without needing Prisma Python client. 🎉
