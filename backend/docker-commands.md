# Docker Database Commands - Quick Reference

## 🐳 **PostgreSQL Docker Container**

### **Start/Stop Container**

```bash
# Start container (if stopped)
docker start privfed-postgres

# Stop container
docker stop privfed-postgres

# Restart container
docker restart privfed-postgres

# Remove container (WARNING: Deletes all data!)
docker rm -f privfed-postgres
```

### **View Container Status**

```bash
# Check if running
docker ps | grep privfed-postgres

# View logs
docker logs privfed-postgres

# Follow logs in real-time
docker logs -f privfed-postgres
```

### **Access Database**

```bash
# Access PostgreSQL command line
docker exec -it privfed-postgres psql -U privfed_user -d privfed_db

# Run SQL command directly
docker exec privfed-postgres psql -U privfed_user -d privfed_db -c "SELECT COUNT(*) FROM users;"

# List all tables
docker exec privfed-postgres psql -U privfed_user -d privfed_db -c "\dt"

# View database size
docker exec privfed-postgres psql -U privfed_user -d privfed_db -c "SELECT pg_size_pretty(pg_database_size('privfed_db'));"
```

### **Backup/Restore**

```bash
# Backup database
docker exec privfed-postgres pg_dump -U privfed_user privfed_db > backup.sql

# Restore database
docker exec -i privfed-postgres psql -U privfed_user privfed_db < backup.sql
```

### **Reset Database**

```bash
# Stop container
docker stop privfed-postgres

# Remove container
docker rm privfed-postgres

# Recreate container (fresh start)
docker run --name privfed-postgres `
  -e POSTGRES_USER=privfed_user `
  -e POSTGRES_PASSWORD=privfed_pass `
  -e POSTGRES_DB=privfed_db `
  -p 5432:5432 `
  -d postgres:15

# Wait for container to start
Start-Sleep -Seconds 3

# Run migrations again
cd backend
npm run db:migrate
```

---

## ✅ **Container Created Successfully!**

Your PostgreSQL container is now running with:
- **Container Name:** `privfed-postgres`
- **Database:** `privfed_db`
- **User:** `privfed_user`
- **Password:** `privfed_pass`
- **Port:** `5432`
- **Status:** ✅ Running
