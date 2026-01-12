# Database Setup Guide

## 📋 **PostgreSQL Setup Instructions**

### **Step 1: Install PostgreSQL (if not installed)**

**Windows:**
1. Download PostgreSQL from: https://www.postgresql.org/download/windows/
2. Run installer
3. Remember the password you set for `postgres` user
4. Default port is `5432`

**Or use Docker:**
```bash
docker run --name privfed-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_USER=privfed_user -e POSTGRES_DB=privfed_db -p 5432:5432 -d postgres:15
```

---

### **Step 2: Create Database and User**

Open PostgreSQL command line (`psql`) or pgAdmin, then run:

```sql
-- Connect as postgres superuser
psql -U postgres

-- Create database
CREATE DATABASE privfed_db;

-- Create user
CREATE USER privfed_user WITH PASSWORD 'privfed_pass';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE privfed_db TO privfed_user;

-- Connect to the new database
\c privfed_db

-- Grant schema privileges (important!)
GRANT ALL ON SCHEMA public TO privfed_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO privfed_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO privfed_user;

-- Exit
\q
```

---

### **Step 3: Update .env File**

Edit `backend/.env` and update the `DATABASE_URL` with your credentials:

```env
# If you used the default setup:
DATABASE_URL="postgresql://privfed_user:privfed_pass@localhost:5432/privfed_db?schema=public"

# If using Docker:
DATABASE_URL="postgresql://privfed_user:postgres@localhost:5432/privfed_db?schema=public"

# If PostgreSQL is on a different host/port:
DATABASE_URL="postgresql://username:password@host:port/database?schema=public"
```

**Security Note:** Change `privfed_pass` to a secure password in production!

---

### **Step 4: Test Connection**

```bash
cd backend

# Test connection (if you have psql installed)
psql -U privfed_user -d privfed_db -h localhost

# Or use Prisma to test
npm run db:push  # This will test connection and push schema
```

---

### **Step 5: Run Migrations**

```bash
cd backend

# Create initial migration
npm run db:migrate

# This will:
# 1. Test database connection
# 2. Create migration files in prisma/migrations/
# 3. Apply migrations to database
# 4. Create all tables according to schema.prisma
```

---

### **Step 6: Verify Database**

```bash
# Open Prisma Studio to view database
npm run db:studio

# This opens a web UI at http://localhost:5555
# You can see all tables and data
```

---

## 🔧 **Quick Setup Script (Windows PowerShell)**

Save this as `setup-database.ps1` in the `backend` folder:

```powershell
# PrivFed Database Setup Script
# Run with: .\setup-database.ps1

Write-Host "Setting up PrivFed database..." -ForegroundColor Cyan

# Check if PostgreSQL is installed
try {
    $psqlVersion = psql --version
    Write-Host "✅ PostgreSQL found: $psqlVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ PostgreSQL not found. Please install PostgreSQL first." -ForegroundColor Red
    exit 1
}

# Prompt for postgres password
$postgresPassword = Read-Host "Enter PostgreSQL 'postgres' user password" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($postgresPassword))

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $plainPassword

# Create database
Write-Host "Creating database..." -ForegroundColor Yellow
psql -U postgres -c "CREATE DATABASE privfed_db;" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database created" -ForegroundColor Green
} else {
    Write-Host "⚠️  Database may already exist (this is OK)" -ForegroundColor Yellow
}

# Create user
Write-Host "Creating user..." -ForegroundColor Yellow
psql -U postgres -c "CREATE USER privfed_user WITH PASSWORD 'privfed_pass';" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ User created" -ForegroundColor Green
} else {
    Write-Host "⚠️  User may already exist (this is OK)" -ForegroundColor Yellow
}

# Grant privileges
Write-Host "Granting privileges..." -ForegroundColor Yellow
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE privfed_db TO privfed_user;" 2>&1 | Out-Null
psql -U postgres -d privfed_db -c "GRANT ALL ON SCHEMA public TO privfed_user;"
psql -U postgres -d privfed_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO privfed_user;"
psql -U postgres -d privfed_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO privfed_user;"
Write-Host "✅ Privileges granted" -ForegroundColor Green

# Clear password
$env:PGPASSWORD = $null

Write-Host "`n✅ Database setup complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Update .env file with your credentials" -ForegroundColor White
Write-Host "  2. Run: npm run db:migrate" -ForegroundColor White
Write-Host "  3. Start server: npm run dev" -ForegroundColor White
```

---

## 🐳 **Docker Setup (Easiest Option)**

If you have Docker installed:

```bash
# Run PostgreSQL in Docker
docker run --name privfed-postgres \
  -e POSTGRES_USER=privfed_user \
  -e POSTGRES_PASSWORD=privfed_pass \
  -e POSTGRES_DB=privfed_db \
  -p 5432:5432 \
  -d postgres:15

# Update .env file
DATABASE_URL="postgresql://privfed_user:privfed_pass@localhost:5432/privfed_db?schema=public"

# Run migrations
cd backend
npm run db:migrate
```

**Stop/Start Docker container:**
```bash
# Stop
docker stop privfed-postgres

# Start
docker start privfed-postgres

# Remove (WARNING: Deletes all data)
docker rm -f privfed-postgres
```

---

## 🔍 **Troubleshooting**

### **Connection Error: "password authentication failed"**

**Solution:** Check your password in `.env` matches the database user password.

```bash
# Reset password
psql -U postgres
ALTER USER privfed_user WITH PASSWORD 'new_password';
\q

# Update .env
DATABASE_URL="postgresql://privfed_user:new_password@localhost:5432/privfed_db?schema=public"
```

### **Connection Error: "database does not exist"**

**Solution:** Create the database:
```sql
psql -U postgres
CREATE DATABASE privfed_db;
GRANT ALL PRIVILEGES ON DATABASE privfed_db TO privfed_user;
\q
```

### **Connection Error: "permission denied for schema public"**

**Solution:** Grant schema privileges:
```sql
psql -U postgres -d privfed_db
GRANT ALL ON SCHEMA public TO privfed_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO privfed_user;
\q
```

### **Connection Error: "could not connect to server"**

**Solution:** Check PostgreSQL is running:
```bash
# Windows
Get-Service postgresql*

# Linux/Mac
sudo systemctl status postgresql

# Docker
docker ps | grep postgres
```

### **Port 5432 Already in Use**

**Solution:** Use a different port:
```env
DATABASE_URL="postgresql://privfed_user:privfed_pass@localhost:5433/privfed_db?schema=public"
```

---

## ✅ **Verification Checklist**

After setup, verify everything works:

- [ ] PostgreSQL is running
- [ ] Database `privfed_db` exists
- [ ] User `privfed_user` exists and has privileges
- [ ] `.env` file has correct `DATABASE_URL`
- [ ] `npm run db:migrate` runs without errors
- [ ] `npm run db:studio` opens successfully
- [ ] `npm run dev` starts server without database errors

---

## 🚀 **Next Steps After Database Setup**

1. **Run migrations:**
   ```bash
   npm run db:migrate
   ```

2. **Start server:**
   ```bash
   npm run dev
   ```

3. **Test endpoints:**
   ```bash
   curl http://localhost:8000/api/health
   curl http://localhost:8000/api/status
   ```

4. **Seed database (optional):**
   ```bash
   # Create some test banks
   # You can do this via API or manually via Prisma Studio
   npm run db:studio
   ```

---

**Need help?** Check Prisma docs: https://www.prisma.io/docs/getting-started
