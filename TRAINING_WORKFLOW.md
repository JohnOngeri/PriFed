# Training Workflow Guide

## ✅ **RECOMMENDED SEQUENCE**

### **Phase 1: Backend Testing (Current)**
1. ✅ Backend implementation complete
2. 🔄 **Test backend endpoints** (DO THIS NOW)
3. ✅ Verify database connectivity
4. ✅ Verify API responses match Flutter expectations

### **Phase 2: Model Training (Next)**
5. 🔄 **Train federated learning models**
6. 🔄 **Store training results in database**
7. 🔄 **Test integration with Flutter app**

---

## 🧪 **STEP 1: Test Backend First**

**Why test first?**
- Ensures database is properly set up
- Verifies API endpoints work correctly
- Confirms Flutter can communicate with backend
- Training results will need to be stored in the database

**Quick Test Checklist:**
```bash
# 1. Start PostgreSQL
# 2. Set up database
cd backend
npm install
npm run db:generate
npm run db:migrate

# 3. Start Node.js backend
npm run dev

# 4. Test endpoints
curl http://localhost:8000/api/health
curl http://localhost:8000/api/status
curl http://localhost:8000/api/metrics/global
curl http://localhost:8000/api/privacy
curl http://localhost:8000/api/rounds
```

**Expected:** All endpoints should return valid JSON responses (even if empty data)

---

## 🚀 **STEP 2: Train Models (After Testing)**

You have two Python training scripts ready:

### **Option A: Standard Federated Training**
```bash
cd backend
python scripts/run_federated_training.py
```

**What it does:**
- Uses Flower framework for federated learning
- Trains fraud detection model across multiple banks
- Aggregates model updates using FedAvg/FedProx/FedOpt
- Saves results to `backend/results/`

### **Option B: Federated Training with Differential Privacy**
```bash
cd backend
python scripts/run_federated_dp_training.py
```

**What it does:**
- Same as Option A, but adds privacy-preserving mechanisms
- Uses differential privacy (Opacus or manual DP)
- Tracks privacy budget (epsilon, delta)
- Better for production with sensitive data

---

## 🔗 **STEP 3: Integrate Training with Backend**

**Critical:** After training, you need to **store results in the database** so the Flutter app can display them.

### **Current Gap:**
- ✅ Python scripts train models and save to files
- ❌ Training results are NOT automatically stored in PostgreSQL
- ❌ Flutter app reads from `/api/metrics/*` which queries the database

### **Required Integration:**

Create a script to sync training results to database:

```python
# backend/scripts/sync_training_to_db.py
"""
Sync training results from Python scripts to Node.js database
"""
import json
from prisma import Prisma
import asyncio

async def sync_training_round(results_file: str):
    """Sync a training round's results to PostgreSQL"""
    prisma = Prisma()
    await prisma.connect()
    
    # Load training results
    with open(results_file) as f:
        results = json.load(f)
    
    # Create training round in database
    for round_data in results['history']:
        round_num = round_data['round']
        
        # Create global metrics
        global_metrics = await prisma.classificationmetrics.create({
            data: {
                auc: round_data['metrics']['auc'],
                accuracy: round_data['metrics']['accuracy'],
                precision: round_data['metrics']['precision'],
                recall: round_data['metrics']['recall'],
                f1: round_data['metrics']['f1'],
                loss: round_data['metrics']['loss']
            }
        })
        
        # Create training round
        training_round = await prisma.traininground.create({
            data: {
                roundNumber: round_num,
                status: 'COMPLETED',
                globalMetricsId: global_metrics.id,
                startedAt: round_data['started_at'],
                completedAt: round_data['completed_at']
            }
        })
        
        # Create bank-specific metrics
        for bank_id, bank_metrics in round_data['bank_metrics'].items():
            bank = await prisma.bank.find_unique({
                where: { bankId: bank_id }
            })
            
            if bank:
                bank_metrics_record = await prisma.classificationmetrics.create({
                    data: {
                        auc: bank_metrics['auc'],
                        accuracy: bank_metrics['accuracy'],
                        precision: bank_metrics['precision'],
                        recall: bank_metrics['recall'],
                        f1: bank_metrics['f1'],
                        loss: bank_metrics['loss']
                    }
                })
                
                await prisma.banktraininground.create({
                    data: {
                        roundId: training_round.id,
                        bankId: bank.id,
                        metricsId: bank_metrics_record.id,
                        samples: bank_metrics['num_samples'],
                        fraudRate: bank_metrics['fraud_rate']
                    }
                })
        
        # Create privacy metrics if available
        if 'privacy_metrics' in round_data:
            privacy_metrics = await prisma.privacymetrics.create({
                data: {
                    currentEpsilon: round_data['privacy_metrics']['current_epsilon'],
                    targetEpsilon: round_data['privacy_metrics']['target_epsilon'],
                    delta: round_data['privacy_metrics']['delta'],
                    noiseMultiplier: round_data['privacy_metrics']['noise_multiplier'],
                    privacyStrength: round_data['privacy_metrics']['privacy_strength'],
                    budgetUsedPercentage: round_data['privacy_metrics']['budget_used_percentage']
                }
            })
            
            await prisma.traininground.update({
                where: { id: training_round.id },
                data: { privacyMetricsId: privacy_metrics.id }
            })
    
    await prisma.disconnect()
    print("Training results synced to database!")

if __name__ == '__main__':
    asyncio.run(sync_training_round('backend/results/training_results.json'))
```

---

## 📋 **RECOMMENDED WORKFLOW**

### **Today: Test Backend**
1. ✅ Set up PostgreSQL database
2. ✅ Configure `.env` file
3. ✅ Run `npm install` and `npm run db:migrate`
4. ✅ Start server: `npm run dev`
5. ✅ Test all endpoints with curl or Postman
6. ✅ Verify Flutter app can connect (if ready)

### **This Week: Train Models**
1. ✅ Ensure dataset files are ready (`dataset/` directory)
2. ✅ Configure training parameters in `backend/configs/config.yaml`
3. ✅ Run federated training: `python scripts/run_federated_training.py`
4. ✅ Review training results in `backend/results/`
5. ✅ Sync results to database using sync script
6. ✅ Verify Flutter app displays training results

### **Next Week: Integration & Production**
1. ✅ Automate training → database sync
2. ✅ Set up scheduled training runs
3. ✅ Monitor model performance
4. ✅ Deploy to production environment

---

## ⚠️ **IMPORTANT NOTES**

### **1. Database Must Be Set Up First**
Training results need to be stored, so database must work before training.

### **2. Dataset Required**
Ensure you have:
- `dataset/train_transaction.csv`
- `dataset/train_identity.csv`
- `dataset/test_transaction.csv`
- `dataset/test_identity.csv`

### **3. Python Environment**
Make sure you have:
```bash
cd backend
pip install -r requirements.txt
```

### **4. Integration Bridge Needed**
Currently, Python training scripts and Node.js backend are separate. You'll need to:
- Option A: Create sync script (as shown above)
- Option B: Modify training scripts to directly write to database
- Option C: Create a REST API bridge that training scripts call

---

## 🎯 **ANSWER TO YOUR QUESTION**

**"Should I go to training the models next after testing?"**

**YES, but with this sequence:**

1. ✅ **Test backend first** (30 minutes - 1 hour)
   - Verify database works
   - Verify endpoints respond
   - Fix any remaining issues

2. ✅ **Then train models** (2-4 hours depending on config)
   - Run federated training script
   - Review results
   - **CRITICAL:** Sync results to database

3. ✅ **Verify integration** (30 minutes)
   - Check Flutter app displays training results
   - Verify metrics endpoints return real data
   - Test end-to-end flow

**Don't skip testing** - if the database isn't set up correctly, training results will just sit in files and won't be accessible to your Flutter app!

---

## 🚀 **Quick Start Commands**

```bash
# 1. Test Backend (DO THIS FIRST)
cd backend
npm install
npm run db:generate
npm run db:migrate
npm run dev

# In another terminal, test endpoints:
curl http://localhost:8000/api/health
curl http://localhost:8000/api/status

# 2. Train Models (AFTER testing)
cd backend
pip install -r requirements.txt
python scripts/run_federated_training.py

# 3. Sync Results to Database (NEW SCRIPT NEEDED)
python scripts/sync_training_to_db.py

# 4. Verify Integration
curl http://localhost:8000/api/metrics/global
# Should now return real training data!
```

---

**Bottom Line:** Test backend → Train models → Sync to database → Verify Flutter integration

**Estimated Time:**
- Backend testing: 1 hour
- Model training: 2-4 hours
- Database sync: 1 hour (creating script)
- Total: ~4-6 hours
