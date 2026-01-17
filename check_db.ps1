#!/usr/bin/env pwsh
# Check and initialize database if needed

Write-Host "[CHECK] Database Initialization Status" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if tables exist
Write-Host "Checking if tables exist..." -ForegroundColor Yellow

$checkSQL = @"
SELECT EXISTS(
  SELECT 1 FROM information_schema.tables 
  WHERE table_name = 'feeds' AND table_schema = 'public'
);
"@

try {
    $result = $checkSQL | docker-compose exec -T postgres psql -U ultrabot -d ultrabot 2>&1 | Select-String "t"
    
    if ($result -match "t") {
        Write-Host "[OK] Database tables already exist!" -ForegroundColor Green
        Write-Host ""
        
        # Show table statistics
        Write-Host "Table Statistics:" -ForegroundColor Yellow
        
        $statsSQL = @"
SELECT 
    table_name,
    (SELECT count(*) FROM information_schema.columns c WHERE c.table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
"@
        
        $statsSQL | docker-compose exec -T postgres psql -U ultrabot -d ultrabot
        
        Write-Host ""
        
        # Check feeds count
        $feedsCountSQL = "SELECT COUNT(*) FROM feeds;"
        Write-Host "Feeds in database:" -ForegroundColor Yellow
        $feedsCountSQL | docker-compose exec -T postgres psql -U ultrabot -d ultrabot
        
        Write-Host ""
        
        # Check news items count
        $newsCountSQL = "SELECT COUNT(*) FROM news_items;"
        Write-Host "News items in database:" -ForegroundColor Yellow
        $newsCountSQL | docker-compose exec -T postgres psql -U ultrabot -d ultrabot
        
    } else {
        Write-Host "[ERROR] Database tables do NOT exist!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please run database initialization:" -ForegroundColor Yellow
        Write-Host "  .\init-db.ps1" -ForegroundColor Cyan
    }
} catch {
    Write-Host "[ERROR] Could not check database: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
