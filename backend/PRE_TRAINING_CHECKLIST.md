# Pre-Training Verification Checklist

## ✅ **Complete System Verification Before Training**

Before starting model training, verify all components are working correctly.

---

## 🔍 **1. Database Verification**

### **Check 1.1: Docker Container Running**
```bash
docker ps | grep privfed-postgres
```
**Expected:** Container `privfed-postgres` should be running

### **Check 1.2: Database Connection**
```bash
docker exec privfed-postgres psql -U privfed_user -d privfed_db -c "SELECT version();"
```
**Expected:** PostgreSQL version should be displayed

### **Check 1.3: Tables Created**
```bash
docker exec privfed-postgres psql -U privfed_user -d privfed_db -c "\dt"
```
**Expected:** Should show 15+ tables including:
- users
- banks
- training_rounds
- classification_metrics
- privacy_metrics
- fraud_transactions
- etc.

### **Check 1.4: Prisma Connection**
```bash
cd backend
npm run db:generate
npx prisma db pull --print
```
**Expected:** Should connect successfully and print schema

---

## 🚀 **2. Node.js Backend Verification**

### **Check 2.1: Environment Configuration**
```bash
cd backend
Get-Content .env | Select-String "DATABASE_URL"
```
**Expected:** Should show `DATABASE_URL="postgresql://privfed_user:privfed_pass@localhost:5432/privfed_db?schema=public"`

### **Check 2.2: Dependencies Installed**
```bash
cd backend
npm list --depth=0
```
**Expected:** All dependencies should be listed without errors

### **Check 2.3: Start Server**
```bash
cd backend
npm run dev
```
**Expected:** Server should start on port 8000 without errors

### **Check 2.4: Health Endpoint**
```bash
curl http://localhost:8000/api/health
```
**Expected:** Should return JSON with `status: "ok"`

### **Check 2.5: All API Endpoints**
Test these endpoints (should not crash, even if empty data):
```bash
curl http://localhost:8000/api/status
curl http://localhost:8000/api/metrics/global
curl http://localhost:8000/api/metrics/banks
curl http://localhost:8000/api/privacy
curl http://localhost:8000/api/rounds?limit=10
curl http://localhost:8000/api/dataset/info
curl http://localhost:8000/api/analytics/fairness
curl http://localhost:8000/api/banks
```
**Expected:** All should return valid JSON responses (may be empty data)

---

## 🐍 **3. Python Training Environment Verification**

### **Check 3.1: Python Version**
```bash
python --version
```
**Expected:** Python 3.8+ (preferably 3.10+)

### **Check 3.2: Python Dependencies**
```bash
cd backend
pip list | Select-String "torch|flwr|pandas|numpy|scikit-learn"
```
**Expected:** Should show:
- torch
- flwr (flower)
- pandas
- numpy
- scikit-learn

### **Check 3.3: Install Missing Dependencies**
```bash
cd backend
pip install -r requirements.txt
```
**Expected:** All packages should install successfully

### **Check 3.4: Training Scripts Exist**
```bash
cd backend
Test-Path scripts/run_federated_training.py
Test-Path scripts/sync_training_to_api.py
```
**Expected:** Both files should exist

---

## 📊 **4. Dataset Verification**

### **Check 4.1: Dataset Files Exist**
```bash
Test-Path dataset/train_transaction.csv
Test-Path dataset/train_identity.csv
Test-Path dataset/test_transaction.csv
Test-Path dataset/test_identity.csv
```
**Expected:** All 4 files should exist

### **Check 4.2: Dataset Path Configuration**
```bash
cd backend
Get-Content configs/config.yaml | Select-String "dataset_path"
```
**Expected:** Should show correct path to dataset folder

### **Check 4.3: Dataset Size (Optional)**
```bash
Get-ChildItem dataset/*.csv | Select-Object Name, Length
```
**Expected:** Files should have reasonable sizes (not empty)

---

## 🔗 **5. Integration Verification**

### **Check 5.1: Training API Endpoint**
With server running, test the training results API:
```bash
curl -X POST http://localhost:8000/api/training/rounds `
  -H "Content-Type: application/json" `
  -d '{"round": 999, "global_metrics": {"auc": 0.95, "accuracy": 0.94, "precision": 0.93, "recall": 0.95, "f1": 0.94}}'
```
**Expected:** Should return 201 Created with success message

### **Check 5.2: Verify Data Stored**
```bash
curl http://localhost:8000/api/metrics/global?round_num=999
```
**Expected:** Should return the test round data

### **Check 5.3: Clean Test Data (Optional)**
After testing, remove test round:
```bash
docker exec privfed-postgres psql -U privfed_user -d privfed_db -c "DELETE FROM training_rounds WHERE round_number = 999;"
```

---

## ✅ **Final Verification Checklist**

Before starting training, ensure:

- [ ] Docker container `privfed-postgres` is running
- [ ] Database tables are created (15+ tables)
- [ ] `.env` file is configured correctly
- [ ] Node.js backend starts without errors
- [ ] All API endpoints respond (health, status, metrics, etc.)
- [ ] Python dependencies are installed
- [ ] Training scripts exist (`run_federated_training.py`, `sync_training_to_api.py`)
- [ ] Dataset files exist (train_transaction.csv, train_identity.csv, etc.)
- [ ] Dataset path in `config.yaml` is correct
- [ ] Training API endpoint accepts data (optional test)
- [ ] Flutter app can connect (if testing integration)

---

## 🚀 **Ready for Training?**

Once all checks pass:
1. Start backend server: `npm run dev` (keep running)
2. Run training: `python scripts/run_federated_training.py`
3. Sync results: `python scripts/sync_training_to_api.py --results results/federated_results.json`
4. Verify in Flutter app or via API

---

**Status:** Run these checks to ensure everything is ready!
