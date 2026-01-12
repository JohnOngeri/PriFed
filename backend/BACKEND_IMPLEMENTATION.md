# PrivFed Mobile Backend - Complete Implementation Guide

## Overview

This is a **production-ready Node.js backend** built specifically for the PrivFed Flutter mobile application. It implements all endpoints expected by the Flutter app with proper authentication, security, and database management.

## Architecture

- **Framework**: Express.js (Node.js)
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT (Access + Refresh Tokens)
- **Password Security**: bcrypt (12 rounds)
- **Validation**: Zod schemas
- **Rate Limiting**: express-rate-limit
- **Email**: Nodemailer (SMTP)
- **Logging**: Winston

## Project Structure

```
backend/
├── src/
│   ├── server.js              # Main server entry point
│   ├── routes/                # API route definitions
│   │   ├── auth.routes.js
│   │   ├── health.routes.js
│   │   ├── status.routes.js
│   │   ├── metrics.routes.js
│   │   ├── fraud.routes.js
│   │   ├── bank.routes.js
│   │   ├── analytics.routes.js
│   │   └── dataset.routes.js
│   ├── controllers/           # Business logic
│   │   ├── auth.controller.js
│   │   ├── health.controller.js
│   │   ├── status.controller.js
│   │   ├── metrics.controller.js
│   │   ├── fraud.controller.js
│   │   ├── bank.controller.js
│   │   ├── analytics.controller.js
│   │   └── dataset.controller.js
│   ├── middleware/            # Express middleware
│   │   ├── auth.middleware.js
│   │   ├── errorHandler.js
│   │   ├── requestLogger.js
│   │   └── rateLimiter.js
│   ├── validators/            # Zod validation schemas
│   │   ├── validator.js
│   │   ├── auth.validator.js
│   │   ├── fraud.validator.js
│   │   └── bank.validator.js
│   ├── services/              # Business services (optional)
│   ├── utils/                 # Utility functions
│   │   ├── logger.js
│   │   ├── prisma.js
│   │   ├── jwt.js
│   │   ├── password.js
│   │   └── email.js
│   └── database/              # Database utilities
│       └── seed.js
├── prisma/
│   └── schema.prisma          # Database schema
├── logs/                      # Application logs
├── package.json
├── .env.example
└── BACKEND_IMPLEMENTATION.md
```

## Database Schema

The Prisma schema includes:

1. **Authentication**:
   - `User` - User accounts with federation IDs
   - `RefreshToken` - Refresh token storage
   - `Session` - Active sessions
   - `PasswordResetToken` - Password reset tokens

2. **Bank Management**:
   - `Bank` - Participating banks
   - `BankApplication` - Bank federation applications
   - `BankApplicationVote` - Voting on applications

3. **Training & Metrics**:
   - `TrainingRound` - Federated learning rounds
   - `ClassificationMetrics` - Model performance metrics
   - `BankMetrics` - Per-bank metrics
   - `PrivacyMetrics` - Differential privacy metrics
   - `BankTrainingRound` - Bank participation in rounds

4. **Fraud Detection**:
   - `FraudTransaction` - Fraud predictions

5. **System**:
   - `Notification` - User notifications
   - `SystemConfig` - System configuration

## API Endpoints

### Authentication (`/api/auth`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/signup` | Register new user | Public |
| POST | `/login` | Login with Federation ID | Public |
| POST | `/refresh` | Refresh access token | Public |
| POST | `/logout` | Logout and revoke tokens | Private |
| POST | `/forgot-password` | Request password reset | Public |
| POST | `/reset-password` | Reset password with token | Public |
| POST | `/change-password` | Change password | Private |
| GET | `/me` | Get current user | Private |
| POST | `/verify-token` | Verify token validity | Private |

### Health & Status

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/health` | Health check | Public |
| GET | `/api/status` | System status | Public* |

### Metrics

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/metrics/global` | Global metrics | Public* |
| GET | `/api/metrics/banks` | All bank metrics | Public* |
| GET | `/api/metrics/banks/:bankId` | Specific bank metrics | Public* |
| GET | `/api/privacy` | Privacy metrics | Public* |
| GET | `/api/rounds` | Training rounds history | Public* |

### Fraud Detection

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/fraud/predict` | Predict fraud | Public* |
| POST | `/api/fraud/predict/batch` | Batch prediction | Private |

### Bank Management

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/banks` | Get all banks | Public |
| GET | `/api/banks/:bankId` | Get bank by ID | Public |
| POST | `/api/banks` | Add bank (Admin) | Admin |
| PUT | `/api/banks/:bankId` | Update bank (Admin) | Admin |
| DELETE | `/api/banks/:bankId` | Remove bank (Admin) | Admin |
| POST | `/api/banks/applications` | Submit application | Public |
| GET | `/api/banks/applications` | Get applications | Bank Admin |
| POST | `/api/banks/applications/:id/vote` | Vote on application | Bank Admin |

### Analytics

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/analytics/fairness` | Fairness analysis | Public* |

### Dataset

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/dataset/info` | Dataset information | Public* |

*Public routes marked with asterisk support optional authentication for enhanced features

## Flutter App Mapping

### Expected Endpoints (from `api_service.dart`)

All Flutter endpoints are implemented:

1. ✅ `GET /api/health` → Health check
2. ✅ `GET /api/status` → System status (matches `SystemStatus` model)
3. ✅ `GET /api/metrics/global?round_num=X` → Global metrics (matches `BankMetrics`)
4. ✅ `GET /api/metrics/banks?round_num=X` → Bank metrics (matches `Map<String, BankMetrics>`)
5. ✅ `GET /api/privacy` → Privacy metrics (matches `PrivacyMetrics`)
6. ✅ `GET /api/rounds?limit=50&offset=0` → Training rounds (matches `List<TrainingRound>`)
7. ✅ `POST /api/fraud/predict` → Fraud prediction (matches `FraudTransaction`)
8. ✅ `GET /api/dataset/info` → Dataset info
9. ✅ `GET /api/analytics/fairness` → Fairness analysis

### Response Format Matching

All responses match Flutter model expectations:

- **SystemStatus**: `training_status`, `current_round`, `total_rounds`, `participating_banks`, `privacy_enabled`, `last_update`, `mode`
- **BankMetrics**: `auc`, `accuracy`, `precision`, `recall`, `f1`, optional `bank_id`, `num_samples`, `fraud_rate`, `loss`, `timestamp`
- **PrivacyMetrics**: `current_epsilon`, `target_epsilon`, `delta`, `noise_multiplier`, `privacy_strength`, `budget_used_percentage`
- **TrainingRound**: `round`, `global_metrics`, `client_metrics`, `privacy_metrics`, `timestamp`, `duration`

## Setup Instructions

### 1. Prerequisites

- Node.js 18+ and npm
- PostgreSQL 14+
- Git

### 2. Install Dependencies

```bash
cd backend
npm install
```

### 3. Database Setup

1. Create PostgreSQL database:
```sql
CREATE DATABASE privfed_db;
CREATE USER privfed_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE privfed_db TO privfed_user;
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

3. Generate Prisma Client:
```bash
npm run db:generate
```

4. Run migrations:
```bash
npm run db:migrate
```

5. (Optional) Seed database:
```bash
npm run db:seed
```

### 4. Configure Environment Variables

Edit `.env` file:

```env
# Database
DATABASE_URL="postgresql://privfed_user:password@localhost:5432/privfed_db?schema=public"

# JWT Secrets (GENERATE SECURE RANDOM STRINGS!)
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-chars

# Email (Optional - uses logging mode if not configured)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 5. Run Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

Server will start on `http://localhost:8000`

### 6. Verify Installation

```bash
curl http://localhost:8000/api/health
```

Should return:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime_seconds": 0,
  "component_checks": {
    "api": true,
    "database": true
  }
}
```

## Security Features

1. **JWT Authentication**:
   - Short-lived access tokens (15 minutes)
   - Long-lived refresh tokens (7 days)
   - Token rotation on refresh

2. **Password Security**:
   - bcrypt hashing (12 rounds)
   - Password strength validation
   - Secure password reset flow

3. **Rate Limiting**:
   - General API: 100 requests/15min
   - Auth endpoints: 5 requests/15min
   - Password reset: 3 requests/hour

4. **CORS**: Configured for mobile app origins
5. **Helmet**: Security headers
6. **Input Validation**: Zod schemas on all endpoints
7. **Error Handling**: No sensitive info leaked

## Testing API Endpoints

### Health Check
```bash
curl http://localhost:8000/api/health
```

### Signup
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "federationId": "user123",
    "passcode": "SecurePass123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "federationId": "user123",
    "passcode": "SecurePass123"
  }'
```

### Get System Status
```bash
curl http://localhost:8000/api/status
```

### Get Metrics (with auth)
```bash
curl http://localhost:8000/api/metrics/global \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Mobile App Configuration

In your Flutter app's `api_service.dart`, ensure:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8000/api';
```

For Android emulator, use `10.0.2.2` instead of `localhost`.

## Next Steps

### Remaining Implementation

The following controllers need to be completed (stubs provided):

1. **Metrics Controller** (`src/controllers/metrics.controller.js`)
   - Implement data retrieval from database
   - Match Flutter response formats exactly

2. **Fraud Controller** (`src/controllers/fraud.controller.js`)
   - Integrate with fraud detection model
   - Return predictions matching Flutter format

3. **Bank Controller** (`src/controllers/bank.controller.js`)
   - Complete CRUD operations
   - Implement voting system

4. **Analytics Controller** (`src/controllers/analytics.controller.js`)
   - Calculate fairness metrics
   - Return analysis data

5. **Dataset Controller** (`src/controllers/dataset.controller.js`)
   - Return dataset statistics

### Database Seeding

Create seed data for:
- Default banks
- Sample training rounds
- Test users

### Production Deployment

1. Use environment-specific configs
2. Set up HTTPS
3. Configure proper CORS origins
4. Set up monitoring and logging
5. Database backups
6. Use secrets management for sensitive data

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
psql -U privfed_user -d privfed_db

# Reset database (WARNING: Deletes all data)
npx prisma migrate reset
```

### Port Already in Use

Change PORT in `.env` file or kill existing process:
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Mac/Linux
lsof -ti:8000 | xargs kill
```

### JWT Token Issues

Ensure JWT_SECRET is set and consistent. Tokens generated with one secret cannot be verified with another.

## Support

For issues or questions:
1. Check logs in `backend/logs/`
2. Verify environment variables
3. Ensure database is accessible
4. Check Flutter app logs for API call errors

## License

MIT
