# Privacy-Preserving Federated Learning for Fraud Detection

**PrivFed** is a privacy-preserving machine learning system for fraud detection across multiple banks **without sharing raw transaction data**. It uses **Federated Learning (FedAvg)** and **Differential Privacy (DP-SGD)** to maintain data sovereignty, improve collective detection accuracy, and reduce leakage risks from model updates.

# Why PrivFed?

Banks want to collaborate to catch fraud patterns that don’t appear inside a single institution but collaboration is blocked by:

- **Privacy constraints** — Raw transaction data cannot be shared (GDPR, PCI-DSS, local data protection laws)
- **Non-IID data** — Each bank has unique customers, transaction distributions, and fraud patterns
- **Security risks** — Model updates can leak sensitive information (membership inference, model inversion)

PrivFed enables **intelligence sharing instead of data sharing.**

# Project Demo (Deployed)
<img width="1365" height="585" alt="image" src="https://github.com/user-attachments/assets/2811198f-4497-4fab-8afc-aa533cbd2460" />
<img width="1365" height="585" alt="image" src="https://github.com/user-attachments/assets/3d359209-d93d-4b8e-bd19-e232ed08a265" />


 Live deployed microservices running on Render using Docker  
Mobile client as an Android APK  
 Backend services + database connected (Auth + AI/ML + PostgreSQL)

### Links
  GitHub Repo: [Repository](https://github.com/JohnOngeri/PriFed)
- **Android APK:** [Download from Google Drive](https://drive.google.com/drive/folders/1qY41_rN4COWteuQQYqy4K2LeoLrDMi1G?usp=sharing)
- **Auth API (Render):** [privfed-auth-node.onrender.com](https://privfed-auth-node.onrender.com)
- **AI/ML API (Render):** [privfed-auth.onrender.com](https://privfed-auth.onrender.com)
-


# Architecture Overview

PrivFed is built as a **Dockerized microservices system**.

## Services

### Auth API (Node.js + Express + Prisma)
Handles authentication, JWT, user management, bank profiles.

### AI/ML API (FastAPI + PyTorch)
Telemetry, privacy controls, fraud inference, federated coordination.

### Database (PostgreSQL)
Stores users, banks, auth state, metadata.
<img width="1365" height="680" alt="image" src="https://github.com/user-attachments/assets/df179bb3-ad57-4141-8c23-d896c0eb6337" />


### Frontend (Flutter)
Mobile dashboard + client UI compiled into APK.

# Privacy Layers

### Federated Learning Layer
Banks train locally and send only model updates (FedAvg).

### Differential Privacy Layer
DP-SGD noise added to prevent leakage from updates.

### Fairness Monitoring Layer
Tracks performance across banks to ensure equitable outcomes.

# System Screenshots 

### App UI (Flutter)
- Login / Bank selection  
- Dashboard (AUC, rounds, metrics)  
- Fraud prediction screens
- <img src="https://github.com/user-attachments/assets/c872f3fb-f080-46fa-9dbf-1f878f8fe8b8" width="200" alt="Screenshot_1772638898" />
- <img src="https://github.com/user-attachments/assets/62a84a8a-5398-42db-8650-30354f09d99b" width="200" alt="Screenshot_1772639118" />
<img src="https://github.com/user-attachments/assets/87784193-0a2b-418b-b1ab-10f2ef972606" width="200" alt="Screenshot_1772639375" />
<img src="https://github.com/user-attachments/assets/5f234792-3f24-4756-917c-5dc3906c5153" width="200" alt="Screenshot_1772640190" />
<img src="https://github.com/user-attachments/assets/2312bccc-2bce-4dcb-956b-82427658708c" width="200" alt="Screenshot_1772640197" />




 

### Docker + Render Deployment
- Render services overview (Auth / AI / DB)  
- Docker build & deploy logs  
- Running containers / service health  

### PostgreSQL / Prisma
- DB schema / migrations  
- Connection status (Render Postgres)  
<img width="1362" height="723" alt="image" src="https://github.com/user-attachments/assets/1acf18d9-874b-4e9e-aa4c-6a53daecaa67" />

### Monitoring / Convergence Proof
- 50-round convergence comparison (Federated vs Local baseline)  
- Grafana-style metric dashboards  
- Multi-node visualization (Nairobi / Lagos / Joburg)  

# Results (Experimental Evidence)

PrivFed was evaluated using the **IEEE-CIS Fraud Detection dataset**.

| Strategy | Final AUC | Description |
|----------|----------|------------|
| Centralized Model | 0.7418 | Theoretical ceiling (not privacy-compliant) |
| PriFed (FedAvg) | 0.7289 | Closed >95% of the intelligence gap while keeping data local |
| PriFed + DP (ε = 8.0) | 0.6674 | Privacy-compliant (utility trade-off) |
| Local-Only Average | 0.5820 | Baseline (silo training performs poorly) |


# “Democratization of AI” (Key Finding)

Bank Gamma (smallest institution) struggled due to highly imbalanced data:

- Local-only AUC: **0.5210**
- After joining PrivFed: **0.7790**

📈 ~50% improvement

This shows the system benefits smaller institutions most — without violating privacy laws.


# Data Engineering & Visualization

**Dataset:** IEEE-CIS Fraud Detection

Pipeline includes:

- Log transforms of transaction amounts  
- Temporal extraction (hour/day/week)  
- Interaction ratios and card/device feature engineering  
- Non-IID partitioning to simulate realistic bank differences  
- Visualization of transaction distribution and fraud-rate per bank  

# Model Architecture (Fraud Classifier)

Optimized MLP for tabular data:

- **Input:** ~432 engineered features  
- **Hidden layers:** 256 → 128 → 64  
- **Activation:** ReLU  
- **Regularization:** BatchNorm + Dropout (0.3)  
- **Optimizer:** Adam (lr=0.001, weight_decay=1e-5)  


# Metrics Used

- AUC-ROC (primary)
- PR-AUC
- Recall (fraud capture)

# Getting Started (Local Development)

PrivFed is decoupled into:

- Node.js Auth API  
- FastAPI AI/ML Server  
- Flutter Mobile App  

## 1) Clone Repo

```bash
git clone https://github.com/JohnOngeri/PriFed.git
cd PriFed
```

## 2) AI Backend (FastAPI — Port 8000)

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
uvicorn api.main:app --reload
```

Runs at: http://localhost:8000  
✅ Keep this terminal running.

## 3) Auth Backend (Node + PostgreSQL — Port 3000)

Make sure PostgreSQL is running and `DATABASE_URL` is set in `backend/.env`.

```bash
cd backend
npm install
npx prisma migrate dev
npm run start
```

Runs at: http://localhost:3000

## 4) Flutter App (Mobile Client)

```bash
cd frontend/mobile_app
flutter pub get
flutter run
```

### Android Emulator Notes

- Emulator connects via `10.0.2.2`
- Ensure both backends are running locally


# Build APK

### Debug APK

```bash
cd frontend/mobile_app
flutter build apk --debug
```

Output:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

### Release APK (Production Backends)

```bash
cd frontend/mobile_app
flutter build apk --release \
--dart-define=PRODUCTION=true \
--dart-define=AUTH_BASE_URL=https://auth.example.com/api \
--dart-define=API_BASE_URL=https://api.example.com/api
```

Output:
```
build/app/outputs/flutter-apk/app-release.apk
```

# Deployment (Docker + Render)

This project uses a Dockerized microservices deployment to ensure the APK works anywhere without local backends.

| Component | Tech | Port | Purpose |
|-----------|------|------|----------|
| Auth API | Node.js + Express + Prisma | 3000 | Login, JWT, bank/user management |
| AI/ML API | FastAPI + PyTorch | 8000 | Telemetry, privacy, fraud inference |
| Database | PostgreSQL | 5432 | Auth + metadata |
| Frontend | Flutter | — | Client UI (APK) |

Add your `render.yaml`, `docker-compose` diagram, or service URLs here once screenshots are attached.

# Tech Stack

- Federated Learning: Flower (flwr), FedAvg  
- Deep Learning: PyTorch  
- Differential Privacy: Opacus (DP-SGD)  
- Backend APIs: FastAPI + Node.js  
- Database: PostgreSQL + Prisma  
- Frontend: Flutter (Android APK)  
- Infra: Docker + Render  

# Future Work

- Adaptive privacy budgets (dynamic ε)  
- Early stopping (DP noise accumulates across rounds)  
- Edge deployment (POS terminals / ATMs for real-time detection)  
- Formal regulatory adoption for AML/fraud systems  

---

# Project Files

- `colab_training_notebook (1).ipynb` — ML pipeline, data partitioning, DP-SGD experiments  
- `backend/api/main.py` — FastAPI AI/Telemetry server  
- `backend/src/server.js` — Node Auth server  
- `backend/prisma/schema.prisma` — PostgreSQL schema  
- `frontend/mobile_app/lib/screens/` — Flutter UI + telemetry logic  
- `John Ongeri Ouma Research Proposal (Final).pdf` — Research framework and timeline  
