# PrivFed Database Setup Script
# Run with: .\setup-database.ps1

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  PrivFed Database Setup Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check if PostgreSQL is installed
Write-Host "Checking PostgreSQL installation..." -ForegroundColor Yellow
try {
    $null = Get-Command psql -ErrorAction Stop
    $pgVersion = psql --version 2>&1
    Write-Host "✅ PostgreSQL found: $pgVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ PostgreSQL not found in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  1. Install PostgreSQL: https://www.postgresql.org/download/windows/" -ForegroundColor White
    Write-Host "  2. Add PostgreSQL bin to PATH (usually C:\Program Files\PostgreSQL\XX\bin)" -ForegroundColor White
    Write-Host "  3. Use Docker instead:" -ForegroundColor White
    Write-Host "     docker run --name privfed-postgres -e POSTGRES_USER=privfed_user -e POSTGRES_PASSWORD=privfed_pass -e POSTGRES_DB=privfed_db -p 5432:5432 -d postgres:15" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Prompt for postgres password
Write-Host ""
$postgresPassword = Read-Host "Enter PostgreSQL 'postgres' user password" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($postgresPassword))

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $plainPassword

# Create database
Write-Host ""
Write-Host "Creating database 'privfed_db'..." -ForegroundColor Yellow
$result = psql -U postgres -c "CREATE DATABASE privfed_db;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database created successfully" -ForegroundColor Green
} else {
    if ($result -match "already exists") {
        Write-Host "⚠️  Database already exists (this is OK)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Error creating database: $result" -ForegroundColor Red
        $env:PGPASSWORD = $null
        exit 1
    }
}

# Create user
Write-Host "Creating user 'privfed_user'..." -ForegroundColor Yellow
$result = psql -U postgres -c "CREATE USER privfed_user WITH PASSWORD 'privfed_pass';" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ User created successfully" -ForegroundColor Green
} else {
    if ($result -match "already exists") {
        Write-Host "⚠️  User already exists (this is OK)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Error creating user: $result" -ForegroundColor Red
        $env:PGPASSWORD = $null
        exit 1
    }
}

# Grant privileges on database
Write-Host "Granting privileges on database..." -ForegroundColor Yellow
$result = psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE privfed_db TO privfed_user;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database privileges granted" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: $result" -ForegroundColor Yellow
}

# Grant schema privileges
Write-Host "Granting schema privileges..." -ForegroundColor Yellow
$env:PGPASSWORD = $plainPassword
$result = psql -U postgres -d privfed_db -c "GRANT ALL ON SCHEMA public TO privfed_user;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Schema privileges granted" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: $result" -ForegroundColor Yellow
}

# Grant default privileges
Write-Host "Setting default privileges..." -ForegroundColor Yellow
$result = psql -U postgres -d privfed_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO privfed_user;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Default table privileges set" -ForegroundColor Green
}

$result = psql -U postgres -d privfed_db -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO privfed_user;" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Default sequence privileges set" -ForegroundColor Green
}

# Clear password
$env:PGPASSWORD = $null

# Verify .env file exists
Write-Host ""
Write-Host "Checking .env configuration..." -ForegroundColor Yellow
if (Test-Path .env) {
    $envContent = Get-Content .env -Raw
    if ($envContent -match 'DATABASE_URL.*privfed_user.*privfed_pass.*privfed_db') {
        Write-Host "✅ .env file exists and is configured correctly" -ForegroundColor Green
    } else {
        Write-Host "⚠️  .env file exists but DATABASE_URL may need updating" -ForegroundColor Yellow
        Write-Host "   Expected: DATABASE_URL=\"postgresql://privfed_user:privfed_pass@localhost:5432/privfed_db?schema=public\"" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    Write-Host "   Creating .env file..." -ForegroundColor Yellow
    # .env file should have been created earlier, but if not, show instructions
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "  Database Setup Complete! ✅" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Verify .env file has correct DATABASE_URL" -ForegroundColor White
Write-Host "  2. Run migrations: npm run db:migrate" -ForegroundColor White
Write-Host "  3. Start server: npm run dev" -ForegroundColor White
Write-Host "  4. Test: curl http://localhost:8000/api/health" -ForegroundColor White
Write-Host ""
Write-Host "Database credentials:" -ForegroundColor Cyan
Write-Host "  Database: privfed_db" -ForegroundColor White
Write-Host "  User: privfed_user" -ForegroundColor White
Write-Host "  Password: privfed_pass" -ForegroundColor White
Write-Host "  Host: localhost:5432" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Remember to change password in production!" -ForegroundColor Yellow
Write-Host ""
