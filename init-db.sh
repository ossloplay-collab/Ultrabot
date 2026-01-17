#!/bin/bash
# Ultrabot Database Initialization Script for Linux/macOS
# Creates all necessary tables and views in PostgreSQL

set -e

echo "🚀 Ultrabot Database Initialization Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose is not installed!${NC}"
    exit 1
fi

# Check if Docker is running
echo -e "${YELLOW}Checking Docker status...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    echo -e "${YELLOW}Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"
echo ""

# Check if PostgreSQL container is running
echo -e "${YELLOW}Checking PostgreSQL container...${NC}"
if ! docker-compose ps postgres | grep -q "Up"; then
    echo -e "${YELLOW}Starting PostgreSQL...${NC}"
    docker-compose up -d postgres
    sleep 5
fi
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
echo ""

# Create tables
echo -e "${YELLOW}Creating database tables...${NC}"
echo ""

# Execute SQL initialization script
if [ -f "docker/init.sql" ]; then
    echo -e "${YELLOW}Using SQL script: docker/init.sql${NC}"
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot < docker/init.sql
else
    echo -e "${YELLOW}Running inline SQL commands...${NC}"
    
    # Enable UUID extension
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
    
    # Create feeds table
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot << 'EOF'
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
EOF
    
    # Create news_items table
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot << 'EOF'
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
EOF
    
    # Create publications table
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot << 'EOF'
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
EOF
    
    # Create metrics_logs table
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot << 'EOF'
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
EOF
    
    # Create deduplication_cache table
    docker-compose exec -T postgres psql -U ultrabot -d ultrabot << 'EOF'
CREATE TABLE IF NOT EXISTS deduplication_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_hash VARCHAR(64) NOT NULL UNIQUE,
    feed_id UUID REFERENCES feeds(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT now(),
    expires_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS ix_dedup_cache_feed_id ON deduplication_cache(feed_id);
CREATE INDEX IF NOT EXISTS ix_dedup_cache_expires_at ON deduplication_cache(expires_at);
EOF
fi

echo -e "${GREEN}✅ Tables created${NC}"
echo ""

# Create views
echo -e "${YELLOW}Creating database views...${NC}"
docker-compose exec -T postgres psql -U ultrabot -d ultrabot << 'EOF'
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
EOF

echo -e "${GREEN}✅ Views created${NC}"
echo ""

# Verify tables
echo -e "${YELLOW}Verifying tables...${NC}"
echo ""
docker-compose exec -T postgres psql -U ultrabot -d ultrabot -c "\dt"
echo ""

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}✅ Database initialization complete!${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo -e "  📊 Tables: feeds, news_items, publications, metrics_logs, deduplication_cache"
echo -e "  👁️  Views: published_news_summary, pending_publications, feed_statistics"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  1. Add RSS feeds to database:"
echo -e "     ${YELLOW}docker-compose exec postgres psql -U ultrabot -d ultrabot -c \"SELECT * FROM feeds;\"${NC}"
echo ""
echo -e "  2. Monitor news collection:"
echo -e "     ${YELLOW}docker-compose logs -f bot${NC}"
echo ""
echo -e "  3. Check published news:"
echo -e "     ${YELLOW}docker-compose exec postgres psql -U ultrabot -d ultrabot -c \"SELECT * FROM published_news_summary;\"${NC}"
echo ""
