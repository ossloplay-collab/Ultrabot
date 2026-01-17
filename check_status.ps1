# Global Status Check Script for Windows
# Usage: .\check_status.ps1

Write-Host "🌍 Starting Global Status Check..." -ForegroundColor Cyan

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found" -ForegroundColor Red
    exit 1
}

# Run the Python script
python check_status.py

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Status check completed successfully" -ForegroundColor Green
} else {
    Write-Host "`n❌ Status check failed" -ForegroundColor Red
    exit 1
}
