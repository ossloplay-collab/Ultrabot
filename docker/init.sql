-- Ultrabot Database Initialization Script
-- Creates all necessary tables for the application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- FEEDS TABLE - RSS feed sources
-- ============================================================================
CREATE TABLE IF NOT EXISTS feeds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    url VARCHAR(2048) NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT true,
    priority_weight INT DEFAULT 5,
    
    -- Tracking
    last_fetch_at TIMESTAMP DEFAULT now(),
    last_fetch_success BOOLEAN DEFAULT true,
    consecutive_failures INT DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_feeds_enabled ON feeds(enabled);
CREATE INDEX IF NOT EXISTS ix_feeds_last_fetch_at ON feeds(last_fetch_at);

-- ============================================================================
-- NEWS_ITEMS TABLE - Aggregated news articles
-- ============================================================================
CREATE TABLE IF NOT EXISTS news_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feed_id UUID NOT NULL REFERENCES feeds(id) ON DELETE CASCADE,
    
    -- Content (multilingual)
    title_en TEXT NOT NULL,
    title_ru TEXT,
    content_en TEXT NOT NULL,
    content_ru TEXT,
    
    -- Deduplication & Scoring
    dedup_hash VARCHAR(32) NOT NULL UNIQUE,
    score INT DEFAULT 0,
    
    -- Source information
    source_url VARCHAR(2048) NOT NULL,
    source_name VARCHAR(255) NOT NULL,
    source_weight INT DEFAULT 5,
    
    -- Media attachments
    image_urls JSONB DEFAULT '[]'::jsonb,
    video_urls JSONB DEFAULT '[]'::jsonb,
    hashtags JSONB DEFAULT '[]'::jsonb,
    
    -- Publication state
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP,
    publication_attempts INT DEFAULT 0,
    
    -- Source timestamps
    published_at_source TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_news_items_feed_id ON news_items(feed_id);
CREATE INDEX IF NOT EXISTS ix_news_items_dedup_hash ON news_items(dedup_hash);
CREATE INDEX IF NOT EXISTS ix_news_items_is_published ON news_items(is_published);
CREATE INDEX IF NOT EXISTS ix_news_items_score ON news_items(score);
CREATE INDEX IF NOT EXISTS ix_news_items_created_at ON news_items(created_at);

-- ============================================================================
-- PUBLICATIONS TABLE - Published content records
-- ============================================================================
CREATE TABLE IF NOT EXISTS publications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    news_item_id UUID NOT NULL UNIQUE REFERENCES news_items(id) ON DELETE CASCADE,
    
    -- Telegram publication data
    telegram_message_id BIGINT UNIQUE,
    telegram_html_text TEXT DEFAULT '',
    
    -- Media for publication
    image_urls JSONB DEFAULT '[]'::jsonb,
    video_urls JSONB DEFAULT '[]'::jsonb,
    hashtags JSONB DEFAULT '[]'::jsonb,
    
    -- Publication status
    status VARCHAR(20) DEFAULT 'pending', -- pending, published, failed, retrying
    last_error TEXT,
    retry_count INT DEFAULT 0,
    next_retry_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT now(),
    published_at TIMESTAMP,
    failed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_publications_news_item_id ON publications(news_item_id);
CREATE INDEX IF NOT EXISTS ix_publications_status ON publications(status);
CREATE INDEX IF NOT EXISTS ix_publications_created_at ON publications(created_at);
CREATE INDEX IF NOT EXISTS ix_publications_next_retry_at ON publications(next_retry_at);

-- ============================================================================
-- METRICS_LOGS TABLE - Performance and event logging
-- ============================================================================
CREATE TABLE IF NOT EXISTS metrics_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(50) NOT NULL, -- feed_fetch, translation, scoring, publishing, etc.
    source VARCHAR(100) NOT NULL,
    duration_ms INT,
    status VARCHAR(20) NOT NULL, -- success, error, timeout
    error_message TEXT,
    timestamp TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_metrics_logs_event_type ON metrics_logs(event_type);
CREATE INDEX IF NOT EXISTS ix_metrics_logs_timestamp ON metrics_logs(timestamp);

-- ============================================================================
-- DEDUPLICATION_CACHE TABLE - Recently seen content hashes (optional)
-- ============================================================================
CREATE TABLE IF NOT EXISTS deduplication_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_hash VARCHAR(64) NOT NULL UNIQUE,
    feed_id UUID REFERENCES feeds(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT now(),
    expires_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_dedup_cache_feed_id ON deduplication_cache(feed_id);
CREATE INDEX IF NOT EXISTS ix_dedup_cache_expires_at ON deduplication_cache(expires_at);

-- ============================================================================
-- VIEW: Published News Summary
-- ============================================================================
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

-- ============================================================================
-- VIEW: Pending Publications
-- ============================================================================
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

-- ============================================================================
-- VIEW: Feed Statistics
-- ============================================================================
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

-- ============================================================================
-- COMMENT: Database Schema Documentation
-- ============================================================================
COMMENT ON TABLE feeds IS 'RSS feed sources for news aggregation';
COMMENT ON TABLE news_items IS 'Aggregated news articles from feeds';
COMMENT ON TABLE publications IS 'Records of published news to Telegram';
COMMENT ON TABLE metrics_logs IS 'Performance and event logging';
COMMENT ON TABLE deduplication_cache IS 'Cache for deduplication checks';

COMMENT ON COLUMN news_items.dedup_hash IS 'MD5 hash for duplicate detection';
COMMENT ON COLUMN news_items.score IS 'Relevance score (0-100) for publishing decision';
COMMENT ON COLUMN publications.status IS 'Publication status: pending, published, failed, retrying';

-- ============================================================================
-- Display completion message
-- ============================================================================
\echo '✅ Database initialization complete!'
\echo 'Tables created:'
\dt
\echo ''
\echo 'Views created:'
\dv
