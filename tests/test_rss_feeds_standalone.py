#!/usr/bin/env python
"""Standalone RSS feeds integration test - no pytest required."""

import asyncio
import hashlib
import sys
from datetime import datetime
from sqlalchemy import create_engine, text


async def test_rss_feeds_integration():
    """Test complete RSS processing workflow."""
    
    # Setup
    print("\n" + "="*70)
    print("[TEST] Complete RSS Feeds Integration Test")
    print("="*70)
    
    # 1. Check database connection
    print("\n[STEP 1] Checking database connection...")
    try:
        from src.core.settings import Settings
        settings = Settings()
        
        # Use synchronous engine for testing
        engine = create_engine(
            str(settings.database_url).replace('postgresql+asyncpg', 'postgresql'),
            echo=False,
            pool_pre_ping=True
        )
        
        with engine.begin() as conn:
            result = conn.execute(text("SELECT 1"))
            assert result.fetchone() is not None
            print("[OK] Database connection successful")
    except Exception as e:
        print(f"[ERROR] Database connection failed: {e}")
        return False

    # 2. Check feeds in database
    print("\n[STEP 2] Checking RSS feeds in database...")
    try:
        with engine.begin() as conn:
            feeds_result = conn.execute(
                text("SELECT id, name, url, enabled, priority_weight FROM feeds ORDER BY priority_weight DESC")
            )
            feeds = feeds_result.fetchall()
            
            print(f"[OK] Found {len(feeds)} feeds:")
            for feed in feeds:
                feed_id, name, url, enabled, priority = feed
                status = "ENABLED" if enabled else "DISABLED"
                print(f"     • {name:20} | Priority: {priority:2} | {status:8} | {url[:50]}...")
            
            if len(feeds) == 0:
                print("[WARN] No feeds found in database!")
                return False
    except Exception as e:
        print(f"[ERROR] Failed to fetch feeds: {e}")
        return False

    # 3. Test RSS Parser with real feeds
    print("\n[STEP 3] Testing RSS Parser with real feeds...")
    try:
        from src.infrastructure.external.rss_parser import FeedParserAdapter
        
        rss_parser = FeedParserAdapter(timeout=30)
        feeds_info = []
        
        for feed in feeds[:3]:  # Test first 3 feeds
            feed_id, name, url, enabled, priority = feed
            
            try:
                print(f"\n     Fetching: {name}")
                print(f"     URL: {url}")
                
                feed_data = await rss_parser.fetch_feed(url)
                entries = feed_data.get("entries", [])
                
                print(f"     [OK] Got {len(entries)} entries from {name}")
                
                if entries:
                    # Show first entry
                    first_entry = entries[0]
                    title = first_entry.get('title', 'N/A')
                    link = first_entry.get('link', 'N/A')
                    published = first_entry.get('published', 'N/A')
                    
                    print(f"     Sample entry:")
                    print(f"       - Title: {title[:60]}...")
                    print(f"       - Link: {link[:60]}...")
                    print(f"       - Published: {str(published)[:20]}...")
                    
                feeds_info.append({
                    'name': name,
                    'url': url,
                    'priority': priority,
                    'entries_count': len(entries),
                    'entries': entries,
                    'feed_id': feed_id
                })
                    
            except Exception as e:
                print(f"     [WARN] Failed to fetch {name}: {str(e)[:80]}")
                feeds_info.append({
                    'name': name,
                    'url': url,
                    'priority': priority,
                    'entries_count': 0,
                    'entries': [],
                    'feed_id': feed_id,
                    'error': str(e)
                })

    except Exception as e:
        print(f"[ERROR] RSS Parser initialization failed: {e}")
        return False

    # 4. Analyze collected news
    print("\n[STEP 4] Analyzing collected news items...")
    total_entries = sum(f['entries_count'] for f in feeds_info)
    print(f"[OK] Total entries collected: {total_entries}")
    
    for feed_info in feeds_info:
        print(f"\n     {feed_info['name']}: {feed_info['entries_count']} entries")
        if 'error' in feed_info:
            print(f"       Error: {feed_info['error'][:60]}")

    # 5. Test scoring for collected entries
    print("\n[STEP 5] Testing news scoring...")
    scored_entries = []
    
    for feed_info in feeds_info:
        for entry in feed_info['entries'][:2]:  # Test first 2 entries from each feed
            try:
                title = entry.get('title', '')
                summary = entry.get('summary', entry.get('description', ''))
                
                # Create simple dedup hash
                dedup_hash = hashlib.md5(
                    f"{title}{summary[:500]}".encode()
                ).hexdigest()
                
                # Check keywords for scoring
                keywords_text = f"{title.lower()} {summary.lower()}"
                gaming_keywords = [
                    'game', 'gaming', 'fps', 'rpg', 'mmo', 'esports',
                    'xbox', 'playstation', 'ps5', 'ps4', 'pc gamer',
                    'nintendo', 'steam', 'gaming news', 'video game', 'trailer'
                ]
                
                keyword_score = 0
                for keyword in gaming_keywords:
                    if keyword in keywords_text:
                        keyword_score += 2
                
                # Calculate base score
                score = min(keyword_score, 20)  # Cap at 20
                
                # Add source weight bonus
                score += feed_info['priority']
                
                scored_entries.append({
                    'feed': feed_info['name'],
                    'title': title[:50],
                    'hash': dedup_hash,
                    'score': score,
                    'meets_threshold': score >= 8
                })
                
            except Exception as e:
                print(f"[WARN] Error scoring entry: {e}")
    
    print(f"[OK] Scored {len(scored_entries)} entries")
    
    # Show scoring results
    print("\n     Scoring Results:")
    if len(scored_entries) > 0:
        passed = sum(1 for e in scored_entries if e['meets_threshold'])
        print(f"     ✓ Passed threshold (>=8): {passed}/{len(scored_entries)}")
        
        for entry in scored_entries[:5]:
            status = "✓" if entry['meets_threshold'] else "✗"
            print(f"     {status} {entry['feed']:15} | Score: {entry['score']:2} | {entry['title'][:30]}...")
    else:
        print("     No entries to score")

    # 6. Check existing database news items
    print("\n[STEP 6] Checking existing news items in database...")
    try:
        with engine.begin() as conn:
            # Count total news items
            total_result = conn.execute(text("SELECT COUNT(*) FROM news_items"))
            total_count = total_result.scalar()
            
            # Count published
            published_result = conn.execute(text("SELECT COUNT(*) FROM news_items WHERE is_published = true"))
            published_count = published_result.scalar()
            
            # Get score distribution
            score_result = conn.execute(text("""
                SELECT 
                    COUNT(*) as count,
                    ROUND(AVG(score)::numeric, 2) as avg_score,
                    MAX(score) as max_score,
                    MIN(score) as min_score
                FROM news_items
            """))
            score_data = score_result.fetchone()
            
            print(f"[OK] Database Statistics:")
            print(f"     • Total news items: {total_count}")
            print(f"     • Published items: {published_count}")
            if score_data[0] > 0:
                count, avg_score, max_score, min_score = score_data
                print(f"     • Avg score: {avg_score}")
                print(f"     • Max score: {max_score}")
                print(f"     • Min score: {min_score}")
            
            # Get distribution by score range
            dist_result = conn.execute(text("""
                SELECT 
                    CASE 
                        WHEN score < 5 THEN 'Low (0-4)'
                        WHEN score < 8 THEN 'Medium (5-7)'
                        WHEN score < 15 THEN 'High (8-14)'
                        ELSE 'Very High (15+)'
                    END as range,
                    COUNT(*) as count
                FROM news_items
                GROUP BY range
                ORDER BY range
            """))
            
            dist_data = dist_result.fetchall()
            print(f"\n     Score Distribution:")
            for range_name, count in dist_data:
                print(f"       - {range_name:20}: {count} items")
                
    except Exception as e:
        print(f"[WARN] Could not fetch database stats: {e}")

    # 7. Test deduplication
    print("\n[STEP 7] Testing deduplication logic...")
    try:
        with engine.begin() as conn:
            # Check for duplicate hashes
            dup_result = conn.execute(text("""
                SELECT dedup_hash, COUNT(*) as count
                FROM news_items
                GROUP BY dedup_hash
                HAVING COUNT(*) > 1
            """))
            
            duplicates = dup_result.fetchall()
            print(f"[OK] Duplicate hash check:")
            print(f"     • Unique hashes with duplicates: {len(duplicates)}")
            
            if duplicates:
                for hash_val, count in duplicates[:3]:
                    print(f"       - Hash {hash_val[:16]}...: {count} items")
            else:
                print(f"       - No duplicates found (deduplication working!)")
                
    except Exception as e:
        print(f"[WARN] Could not check duplicates: {e}")

    # 8. Recommendations
    print("\n[STEP 8] Recommendations & Next Steps:")
    print("""
     If news items are still 0 after 10+ minutes:
     
     1. Check RSS feed URLs are accessible:
        • Try fetching manually: curl -v https://feeds.ign.com/ign/all
        
     2. Check bot logs for RSS parsing errors:
        • docker-compose logs bot | grep -i "rss\\|error\\|exception"
        
     3. Verify environment variables:
        • docker-compose exec bot env | grep RSS_CHECK_INTERVAL
        
     4. Check bot's feed processing loop:
        • The bot should process feeds every RSS_CHECK_INTERVAL seconds (default: 300s)
        
     5. Manually trigger feed processing via API:
        • POST http://localhost:8000/api/feeds/process
        
     6. Check for network issues in container:
        • docker-compose exec bot curl -v https://feeds.ign.com/ign/all
        
     7. Increase logging verbosity:
        • Set LOG_LEVEL=DEBUG in .env
        
     8. Check Telegram bot token is valid:
        • docker-compose exec bot env | grep TELEGRAM_TOKEN
        """)

    print("\n" + "="*70)
    print("[DONE] RSS Feeds Integration Test Complete")
    print("="*70 + "\n")

    return True


if __name__ == "__main__":
    try:
        success = asyncio.run(test_rss_feeds_integration())
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n[FATAL ERROR] {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
