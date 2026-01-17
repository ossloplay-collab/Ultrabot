#!/usr/bin/env pwsh
# Add gaming RSS feeds to Ultrabot database on Windows

Write-Host "[START] Adding Gaming RSS Feeds" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$feedsSQL = @"
INSERT INTO feeds (name, url, priority_weight, enabled) VALUES
('GameSpot', 'https://www.gamespot.com/feeds/mix/', 8, true),
('IGN', 'https://feeds.ign.com/ign/all', 9, true),
('Kotaku', 'https://kotaku.com/rss', 7, true),
('The Verge', 'https://www.theverge.com/rss/index.xml', 6, true),
('PC Gamer', 'https://www.pcgamer.com/feed/', 8, true)
ON CONFLICT (name) DO NOTHING;
"@

Write-Host "Adding feeds to database..." -ForegroundColor Yellow

try {
    $feedsSQL | docker-compose exec -T postgres psql -U ultrabot -d ultrabot | Out-Null
    Write-Host "[OK] Feeds inserted" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to insert feeds: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Verifying feeds..." -ForegroundColor Yellow
Write-Host ""

$verifySql = "SELECT id, name, url, priority_weight, enabled FROM feeds ORDER BY priority_weight DESC;"

try {
    $verifySql | docker-compose exec -T postgres psql -U ultrabot -d ultrabot
    Write-Host ""
    Write-Host "[OK] Feeds verified" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to verify feeds: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "[DONE] Gaming feeds added successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - GameSpot (priority: 8)" -ForegroundColor White
Write-Host "  - IGN (priority: 9) - HIGHEST" -ForegroundColor White
Write-Host "  - Kotaku (priority: 7)" -ForegroundColor White
Write-Host "  - The Verge (priority: 6)" -ForegroundColor White
Write-Host "  - PC Gamer (priority: 8)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Monitor bot collecting feeds:" -ForegroundColor White
Write-Host "     docker-compose logs -f bot" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Check news items being fetched (wait 5-10 min):" -ForegroundColor White
Write-Host "     docker-compose exec postgres psql -U ultrabot -d ultrabot -c " + [char]34 + "SELECT COUNT(*) FROM news_items;" + [char]34 -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Check published news:" -ForegroundColor White
Write-Host "     docker-compose exec postgres psql -U ultrabot -d ultrabot -c " + [char]34 + "SELECT * FROM published_news_summary LIMIT 5;" + [char]34 -ForegroundColor Gray
Write-Host ""
