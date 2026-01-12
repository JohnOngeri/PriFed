# Quick script to update user role to ADMIN
# Usage: docker exec -it privfed-postgres psql -U privfed_user -d privfed_db -c "UPDATE users SET role = 'ADMIN' WHERE email = 'YOUR_EMAIL';"

Write-Host "To update your user role to ADMIN, run:"
Write-Host ""
Write-Host "docker exec -it privfed-postgres psql -U privfed_user -d privfed_db"
Write-Host ""
Write-Host "Then in psql, run:"
Write-Host "  SELECT email, ""federationId"", role FROM users;"
Write-Host "  UPDATE users SET role = 'ADMIN' WHERE email = 'your-email@example.com';"
Write-Host "  \q"
Write-Host ""
Write-Host "Or in one command:"
Write-Host '  docker exec -it privfed-postgres psql -U privfed_user -d privfed_db -c "UPDATE users SET role = ''ADMIN'' WHERE email = ''your-email@example.com'';"'
