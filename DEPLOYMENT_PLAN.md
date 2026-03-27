# PrivFed Deployment Plan: APK Runs Anywhere Without Local Backends

This plan lets the Android APK talk to backends in the cloud so you never need to run servers on your laptop.

---

## 1. Architecture Summary

| Component | Tech | Port (internal) | Purpose |
|-----------|------|------------------|---------|
| **Auth API** | Node.js + Express + Prisma | 3000 | Login, signup, JWT, password reset, users, banks |
| **AI/ML API** | FastAPI + PyTorch | 8000 | Health, status, metrics, privacy, fraud prediction, benchmark |
| **Database** | PostgreSQL | 5432 | Used by Auth API only (Prisma) |
| **Flutter app** | Dart | — | Calls Auth at `AUTH_BASE_URL`, AI at `API_BASE_URL` |

- The app expects **two base URLs** in production: one for auth (`/api` on port 3000) and one for AI (`/api` on port 8000).
- You can deploy as **two public URLs** (e.g. `https://auth.yourdomain.com/api` and `https://api.yourdomain.com/api`) and bake them into the APK at build time.

---

## 2. What the Repo Contains (Line-by-Line Relevant Pieces)

### 2.1 Auth backend (Node) – `backend/src/`

- **`server.js`** – Express app, `PORT` from env (default 3000), CORS, routes under `/api` (auth, health, status, metrics, privacy, rounds, fraud, banks, analytics, dataset, training).
- **`prisma/schema.prisma`** – PostgreSQL; needs `DATABASE_URL`.
- **Env used**: `PORT`, `NODE_ENV`, `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ACCESS_EXPIRY`, `JWT_REFRESH_EXPIRY`, `CORS_ORIGIN`, `FRONTEND_URL`, `SMTP_*` (optional email), `PASSWORD_RESET_EXPIRY`, `DEFAULT_EPSILON`, `DEFAULT_DELTA`, `DEFAULT_NOISE_MULTIPLIER`, `DEFAULT_TOTAL_ROUNDS`.

### 2.2 AI backend (FastAPI) – `backend/api/`

- **`main.py`** – FastAPI app, CORS, `load_config()` from `utils.data_utils` (reads `configs/config.yaml`) or fallback; `ENVIRONMENT`; creates `logs/`, `results/`, `models/` at startup; preloads benchmark models.
- **`routes.py`** – Router with `prefix="/api"`: `/api/health`, `/api/status`, `/api/metrics/*`, `/api/privacy`, `/api/rounds`, `/api/fraud/*`, `/api/dataset/*`, `/api/analytics/*`, etc.
- **`services.py`** – `MODELS_DIR` from env `PRIFED_MODELS_DIR` (default `backend/models`); loads `.pth` models and optional `preprocessing_artifacts.pkl` from that dir.

### 2.3 Flutter app – `frontend/mobile_app/lib/`

- **`config/api_config.dart`** – In production uses `AUTH_BASE_URL` and `API_BASE_URL` from compile-time `String.fromEnvironment` (defaults `https://api.privfed.com/api`). Override (e.g. for dev) is stored in `SharedPreferences` and applied in `ApiService._checkConnection()`.
- **`config/api_config_io.dart`** – Defaults for mobile: Android emulator → `10.0.2.2`, else `localhost`; auth port 3000, AI port 8000.
- **`providers/api_service.dart`** – Two Dio clients: auth and AI; health checks to both; `updateBaseUrl()` for override.

So: **for “APK runs anywhere” you deploy both backends and build the APK with `AUTH_BASE_URL` and `API_BASE_URL` set to your deployed URLs.**

---

## 3. Required Environment Variables

### Auth (Node)

| Variable | Required | Example / notes |
|----------|----------|------------------|
| `DATABASE_URL` | Yes | `postgresql://user:pass@host:5432/privfed` |
| `JWT_SECRET` | Yes (prod) | Strong random string |
| `JWT_REFRESH_SECRET` | Yes (prod) | Strong random string |
| `PORT` | No | Default 3000 |
| `NODE_ENV` | No | `production` |
| `CORS_ORIGIN` | Recommended | Comma-separated origins (or `*` for dev) |
| `FRONTEND_URL` | Optional | For email links, e.g. `privfed://` or your app URL |
| `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, etc. | Optional | If you use password-reset email |

### AI (FastAPI)

| Variable | Required | Example / notes |
|----------|----------|------------------|
| `ENVIRONMENT` | No | `production` for prod behavior |
| `PRIFED_MODELS_DIR` | No | Default `backend/models`; must contain trained `.pth` (and optionally `preprocessing_artifacts.pkl`) for prediction/benchmark |

Config file `configs/config.yaml` is optional; the app has in-code fallbacks for API host/port and CORS.

---

## 4. Deployment Options

### Option A: Docker Compose (VPS / single server)

- Run **Auth** (Node), **AI** (FastAPI), and **PostgreSQL** on one machine.
- Expose **two public URLs** (e.g. via one Nginx or cloud load balancer):
  - `https://auth.yourdomain.com` → Node (port 3000)
  - `https://api.yourdomain.com` → FastAPI (port 8000)
- Build the APK with:
  - `AUTH_BASE_URL=https://auth.yourdomain.com/api`
  - `API_BASE_URL=https://api.yourdomain.com/api`
  - `PRODUCTION=true`

### Option B: Managed services (e.g. Render, Fly.io, Railway)

- Deploy **Auth** and **AI** as two separate services.
- Use a managed PostgreSQL for Auth (e.g. Render PostgreSQL, Neon, Supabase).
- Set the same env vars as above; each service gets its own public URL.
- Build the APK with those two URLs and `PRODUCTION=true`.

### Option C: Single domain with path-based routing (optional)

- One domain, e.g. `https://api.yourdomain.com`.
- Reverse proxy:
  - `/api/auth` and `/api/auth/*` → Node (3000)
  - All other `/api/*` → FastAPI (8000)
- Then you can use a **single** base URL in the app (e.g. `API_BASE_URL=https://api.yourdomain.com/api`) and set **auth base URL** to the same (or a path like `/api/auth` if you add that in the app). This may require a small Flutter change so auth and AI both use the same host with different paths.

**Recommended for minimal change:** Option A or B with two URLs and build-time `AUTH_BASE_URL` + `API_BASE_URL`.

---

## 5. Step-by-Step: Docker-Based Deployment (Option A)

### 5.1 Prepare the server

- VPS (e.g. DigitalOcean, Linode, AWS EC2) with Docker and Docker Compose.
- Domain (or subdomains) pointing to the server’s IP.
- SSL (e.g. Let’s Encrypt) for `auth.yourdomain.com` and `api.yourdomain.com`.

**Minimal run without Nginx:** To test quickly, you can comment out the `nginx`, `prometheus`, `grafana`, and `jupyter` services in `docker-compose.yml` and expose ports 3000 and 8000 directly. Set `CORS_ORIGIN` to `*` or your client origin. For production, put a reverse proxy (Nginx/Traefik) in front with SSL.

### 5.2 Add Auth (Node) to Docker

- **Node Dockerfile** at `backend/Dockerfile.node` (see section 6).
- In **docker-compose**:
  - Add service `privfed-auth` (Node) with `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `CORS_ORIGIN`, etc.
  - Use the same `postgres` service for Prisma (run migrations on startup or in a one-off container).
  - Expose Node on 3000 internally.

### 5.3 Keep AI (FastAPI) as-is

- Existing `backend/Dockerfile` and `privfed-backend` service stay.
- Mount or copy `backend/models` (with `.pth` and optional `preprocessing_artifacts.pkl`) into the container, or set `PRIFED_MODELS_DIR` to a volume that has them.

### 5.4 Reverse proxy (Nginx or Traefik)

- **auth.yourdomain.com** → proxy to `privfed-auth:3000`.
- **api.yourdomain.com** → proxy to `privfed-backend:8000`.
- Terminate SSL at the proxy.

### 5.5 Run

```bash
# From repo root
docker compose up -d
# Run Prisma migrations for Auth (once)
docker compose exec privfed-auth npx prisma migrate deploy
```

### 5.6 Build production APK

From the repo root:

```bash
cd frontend/mobile_app
flutter pub get
flutter build apk --release \
  --dart-define=PRODUCTION=true \
  --dart-define=AUTH_BASE_URL=https://auth.yourdomain.com/api \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

- Replace `auth.yourdomain.com` and `api.yourdomain.com` with your real deployed hostnames (or use a single host with two paths if you implement Option C).
- Output: `build/app/outputs/flutter-apk/app-release.apk`. Install this APK on any device; it will use only the deployed backends (no need to run anything on your laptop).

---

## 6. Node (Auth) Dockerfile

Create `backend/Dockerfile.node` so the existing compose can be extended with an auth service (see next section for compose snippet).

---

## 7. Docker Compose Snippet for Auth

Add a service like this (and ensure `postgres` is used by both; Prisma needs the same DB). Adjust image/build and env as needed.

```yaml
  privfed-auth:
    build:
      context: ./backend
      dockerfile: Dockerfile.node
    container_name: privfed-auth
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DATABASE_URL=postgresql://privfed_user:privfed_secure_password_2024@postgres:5432/privfed
      - JWT_SECRET=${JWT_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
      - CORS_ORIGIN=${CORS_ORIGIN:-*}
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - privfed-network
    restart: unless-stopped
```

Run migrations before or after startup (e.g. in Dockerfile or entrypoint): `npx prisma migrate deploy`.

---

## 8. Checklist for “APK Runs Anywhere”

- [ ] Auth API deployed and reachable at `AUTH_BASE_URL` (e.g. `https://auth.yourdomain.com/api`).
- [ ] AI API deployed and reachable at `API_BASE_URL` (e.g. `https://api.yourdomain.com/api`).
- [ ] PostgreSQL for Auth running and migrated (Prisma).
- [ ] Env vars set (especially `JWT_SECRET`, `JWT_REFRESH_SECRET`, `DATABASE_URL`).
- [ ] Models available to FastAPI container (`PRIFED_MODELS_DIR` or mounted volume with `.pth`).
- [ ] APK built with `PRODUCTION=true`, `AUTH_BASE_URL`, and `API_BASE_URL` pointing at the deployed URLs.
- [ ] No need to run any backend on your laptop; the APK uses the cloud backends only.

---

## 9. Optional: Backend URL Override in the App

For testing or power users, the app already supports an override: if you set `api_base_url` in `SharedPreferences` (e.g. via a settings screen that calls `ApiService.updateBaseUrl(url)`), the app will use that for the AI base URL and derive the auth URL from the same host with port 3000. In production, the primary path is build-time URLs above; override is for flexibility.

---

*End of deployment plan.*
