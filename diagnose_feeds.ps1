#!/usr/bin/env pwsh
# Diagnose why bot is not collecting feeds

Write-Host "[DIAGNOSE] Why Bot Is Not Collecting Feeds" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check bot logs for feed processing
Write-Host "[STEP 1] Checking bot logs for feed processing..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Recent bot logs (last 50 lines):" -ForegroundColor Yellow
docker-compose logs --tail=50 bot | Select-String -Pattern "feed|Feed|RSS|Error|error|exception" -CaseSensitive | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

Write-Host ""

# 2. Check feed table for update times
Write-Host "[STEP 2] Checking when feeds were last updated..." -ForegroundColor Yellow

$feedStatsSQL = @"
SELECT 
    name,
    enabled,
    last_fetch_at,
    last_fetch_success,
    consecutive_failures,
    EXTRACT(EPOCH FROM (now() - last_fetch_at))::INTEGER as seconds_since_fetch
FROM feeds
ORDER BY last_fetch_at DESC;
"@

Write-Host ""
$feedStatsSQL | docker-compose exec -T postgres psql -U ultrabot -d ultrabot

Write-Host ""

# 3. Check if bot is actually running
Write-Host "[STEP 3] Checking if bot service is running..." -ForegroundColor Yellow
Write-Host ""

$botStatus = docker-compose ps --filter "name=bot" --format "json" | ConvertFrom-Json
if ($botStatus -and $botStatus.State -eq "running") {
    Write-Host "[OK] Bot is RUNNING" -ForegroundColor Green
    Write-Host "  Uptime: Since container started" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Bot is NOT running!" -ForegroundColor Red
    Write-Host "  Start it with: docker-compose up -d bot" -ForegroundColor Yellow
}

Write-Host ""

# 4. Check environment variables
Write-Host "[STEP 4] Checking bot environment variables..." -ForegroundColor Yellow
Write-Host ""

Write-Host "RSS Configuration:" -ForegroundColor Yellow
docker-compose exec bot env | Select-String -Pattern "RSS_|MIN_SCORE|LOG_LEVEL" | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

Write-Host ""

# 5. Try manual feed processing
Write-Host "[STEP 5] Checking if bot API is accessible..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 404) {
        Write-Host "[OK] Bot API is responding" -ForegroundColor Green
        Write-Host "  Status Code: $($response.StatusCode)" -ForegroundColor Green
    }
} catch {
    Write-Host "[WARN] Bot API not responding to /health" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# 6. Check docs endpoint
Write-Host "[STEP 6] Checking Swagger API docs..." -ForegroundColor Yellow
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/docs" -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "[OK] Swagger docs available at http://localhost:8000/docs" -ForegroundColor Green
        Write-Host "  You can use it to manually trigger feed processing" -ForegroundColor Green
    }
} catch {
    Write-Host "[WARN] Could not access API docs" -ForegroundColor Yellow
}

Write-Host ""

# 7. Show what to do next
Write-Host "[STEP 7] Next steps to collect news:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Wait for bot to process (automatic every 5 minutes)" -ForegroundColor White
Write-Host "  • Bot processes feeds every RSS_CHECK_INTERVAL seconds (default: 300s = 5 min)" -ForegroundColor Gray
Write-Host "  • Next automatic check around:" -ForegroundColor Gray
Write-Host "    $(Get-Date (Get-Date).AddSeconds(300) -Format 'HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 2: Check extended logs" -ForegroundColor White
Write-Host "  • PowerShell: docker-compose logs -f bot" -ForegroundColor Gray
Write-Host "  • Look for: 'Processing feed', 'Got X entries', 'Error'" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 3: Restart bot to trigger immediate processing" -ForegroundColor White
Write-Host "  • docker-compose restart bot" -ForegroundColor Gray
Write-Host "  • Then monitor: docker-compose logs -f bot" -ForegroundColor Gray
Write-Host ""

Write-Host "Option 4: Check if feeds are URL accessible" -ForegroundColor White
Write-Host "  • From bot container:" -ForegroundColor Gray
Write-Host "    docker-compose exec bot curl -v https://feeds.ign.com/ign/all | head -20" -ForegroundColor Cyan
Write-Host ""

Write-Host "[IMPORTANT] After feeds are processed:" -ForegroundColor Yellow
Write-Host "  1. Check how many news were collected:" -ForegroundColor Gray
Write-Host "     docker-compose exec postgres psql -U ultrabot -d ultrabot -c " + [char]34 + "SELECT COUNT(*) FROM news_items;" + [char]34 -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Check average scores:" -ForegroundColor Gray
Write-Host "     docker-compose exec postgres psql -U ultrabot -d ultrabot -c " + [char]34 + "SELECT AVG(score) FROM news_items;" + [char]34 -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. If scores < 8, news won't be published. Lower MIN_SCORE_THRESHOLD in .env:" -ForegroundColor Yellow
Write-Host "     MIN_SCORE_THRESHOLD=5" -ForegroundColor Cyan

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
