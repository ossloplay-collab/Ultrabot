#!/usr/bin/env pwsh
# Ultrabot Database Initialization Script for Windows PowerShell
# Creates all necessary tables and views in PostgreSQL

Write-Host "🚀 Ultrabot Database Initialization Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop first." -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Docker is running" -ForegroundColor Green
Write-Host ""

# Check if containers are running
Write-Host "Checking containers..." -ForegroundColor Yellow
$containers = docker-compose ps --format json 2>&1 | ConvertFrom-Json
$postgresRunning = $containers | Where-Object { $_.Name -like "*postgres*" -and $_.State -eq "running" }

if (-not $postgresRunning) {
    Write-Host "❌ PostgreSQL container is not running!" -ForegroundColor Red
    Write-Host "Starting containers..." -ForegroundColor Yellow
    docker-compose up -d postgres
    Start-Sleep -Seconds 5
}
Write-Host "✅ PostgreSQL is ready" -ForegroundColor Green
Write-Host ""

# Create tables
Write-Host "Creating database tables..." -ForegroundColor Yellow
Write-Host ""

$sqlStatements = @(
    # Enable UUID extension
    "CREATE EXTENSION IF NOT EXISTS ""uuid-ossp"";"
    
    # Feeds table
    @"
CREATE TABLE IF NOT EXISTS feeds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    url VARCHAR(2048) NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT true,
    priority_weight INT DEFAULT 5,
    last_fetch_at TIMESTAMP DEFAULT now(),
    last_fetch_success BOOLEAN DEFAULT true,
    consecutive_failures INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_feeds_enabled ON feeds(enabled);
CREATE INDEX IF NOT EXISTS ix_feeds_last_fetch_at ON feeds(last_fetch_at);
"@
    
    # News items table
    @"
CREATE TABLE IF NOT EXISTS news_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feed_id UUID NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    title_en TEXT NOT NULL,
    title_ru TEXT,
    content_en TEXT NOT NULL,
    content_ru TEXT,
    dedup_hash VARCHAR(32) NOT NULL UNIQUE,
    score INT DEFAULT 0,
    source_url VARCHAR(2048) NOT NULL,
    source_name VARCHAR(255) NOT NULL,
    source_weight INT DEFAULT 5,
    image_urls JSONB DEFAULT '[]'::jsonb,
    video_urls JSONB DEFAULT '[]'::jsonb,
    hashtags JSONB DEFAULT '[]'::jsonb,
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP,
    publication_attempts INT DEFAULT 0,
    published_at_source TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_news_items_feed_id ON news_items(feed_id);
CREATE INDEX IF NOT EXISTS ix_news_items_dedup_hash ON news_items(dedup_hash);
CREATE INDEX IF NOT EXISTS ix_news_items_is_published ON news_items(is_published);
CREATE INDEX IF NOT EXISTS ix_news_items_score ON news_items(score);
CREATE INDEX IF NOT EXISTS ix_news_items_created_at ON news_items(created_at);
"@
    
    # Publications table
    @"
CREATE TABLE IF NOT EXISTS publications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    news_item_id UUID NOT NULL UNIQUE REFERENCES news_items(id) ON DELETE CASCADE,
    telegram_message_id BIGINT UNIQUE,
    telegram_html_text TEXT DEFAULT '',
    image_urls JSONB DEFAULT '[]'::jsonb,
    video_urls JSONB DEFAULT '[]'::jsonb,
    hashtags JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(20) DEFAULT 'pending',
    last_error TEXT,
    retry_count INT DEFAULT 0,
    next_retry_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    published_at TIMESTAMP,
    failed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_publications_news_item_id ON publications(news_item_id);
CREATE INDEX IF NOT EXISTS ix_publications_status ON publications(status);
CREATE INDEX IF NOT EXISTS ix_publications_created_at ON publications(created_at);
CREATE INDEX IF NOT EXISTS ix_publications_next_retry_at ON publications(next_retry_at);
"@
    
    # Metrics logs table
    @"
CREATE TABLE IF NOT EXISTS metrics_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL,
    source VARCHAR(100) NOT NULL,
    duration_ms INT,
    status VARCHAR(20) NOT NULL,
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_metrics_logs_event_type ON metrics_logs(event_type);
CREATE INDEX IF NOT EXISTS ix_metrics_logs_timestamp ON metrics_logs(timestamp);
"@
    
    # Deduplication cache table
    @"
CREATE TABLE IF NOT EXISTS deduplication_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_hash VARCHAR(64) NOT NULL UNIQUE,
    feed_id UUID REFERENCES feeds(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT now(),
    expires_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_dedup_cache_feed_id ON deduplication_cache(feed_id);
CREATE INDEX IF NOT EXISTS ix_dedup_cache_expires_at ON deduplication_cache(expires_at);
"@
)

foreach ($statement in $sqlStatements) {
    try {
        Write-Host "Executing SQL statement..." -ForegroundColor Gray
        $statement | docker-compose exec -T postgres psql -U ultrabot -d ultrabot | Out-Null
        Write-Host "✅ OK" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Warning: $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Creating views..." -ForegroundColor Yellow

# Create views
$views = @(
    @"
CREATE OR REPLACE VIEW published_news_summary AS
SELECT 
    ni.id,
    ni.title_en,
    ni.title_ru,
    ni.source_name,
    f.name as feed_name,
    ni.score,
    ni.published_at,
    p.status,
    p.telegram_message_id
FROM news_items ni
LEFT JOIN feeds f ON ni.feed_id = f.id
LEFT JOIN publications p ON ni.id = p.news_item_id
WHERE ni.is_published = true
ORDER BY ni.published_at DESC;
"@
    
    @"
CREATE OR REPLACE VIEW pending_publications AS
SELECT 
    p.id,
    ni.title_en,
    ni.title_ru,
    ni.score,
    p.status,
    p.retry_count,
    p.next_retry_at
FROM publications p
JOIN news_items ni ON p.news_item_id = ni.id
WHERE p.status IN ('pending', 'retrying')
ORDER BY p.next_retry_at ASC NULLS FIRST;
"@
    
    @"
CREATE OR REPLACE VIEW feed_statistics AS
SELECT 
    f.id,
    f.name,
    f.url,
    f.enabled,
    COUNT(ni.id) as total_items,
    COUNT(CASE WHEN ni.is_published THEN 1 END) as published_items,
    AVG(ni.score) as avg_score,
    f.last_fetch_at,
    f.last_fetch_success,
    f.consecutive_failures
FROM feeds f
LEFT JOIN news_items ni ON f.id = ni.feed_id
GROUP BY f.id, f.name, f.url, f.enabled, f.last_fetch_at, f.last_fetch_success, f.consecutive_failures;
"@
)

foreach ($view in $views) {
    try {
        Write-Host "Creating view..." -ForegroundColor Gray
        $view | docker-compose exec -T postgres psql -U ultrabot -d ultrabot | Out-Null
        Write-Host "✅ OK" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Warning: $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Verifying tables..." -ForegroundColor Yellow
Write-Host ""

$tableList = docker-compose exec -T postgres psql -U ultrabot -d ultrabot -c "\dt" 2>&1

Write-Host $tableList -ForegroundColor Cyan
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ Database initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  📊 Tables: feeds, news_items, publications, metrics_logs, deduplication_cache" -ForegroundColor White
Write-Host "  👁️  Views: published_news_summary, pending_publications, feed_statistics" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Add RSS feeds to database:" -ForegroundColor White
Write-Host "     docker-compose exec postgres psql -U ultrabot -d ultrabot -c " + [char]34 + "SELECT * FROM feeds;" + [char]34 -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Monitor news collection:" -ForegroundColor White
Write-Host "     docker-compose logs -f bot" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Check published news:" -ForegroundColor White
Write-Host "     docker-compose exec postgres psql -U ultrabot -d ultrabot -c " + [char]34 + "SELECT * FROM published_news_summary;" + [char]34 -ForegroundColor Gray
Write-Host ""
