#!/usr/bin/env python3
"""Script to add popular gaming RSS feeds to the database."""

import asyncio
from datetime import datetime
from uuid import uuid4
from typing import List

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from src.infrastructure.database.models import Base, FeedModel
from src.core.settings import Settings


GAMING_FEEDS = [
    {
        'name': 'GameSpot News',
        'url': 'https://www.gamespot.com/feeds/news/',
        'priority_weight': 8,
    },
    {
        'name': 'IGN Gaming News',
        'url': 'https://feeds.ign.com/ign/all',
        'priority_weight': 9,
    },
    {
        'name': 'Kotaku Gaming',
        'url': 'https://kotaku.com/feed',
        'priority_weight': 7,
    },
    {
        'name': 'The Verge Gaming',
        'url': 'https://www.theverge.com/rss/gaming.xml',
        'priority_weight': 6,
    },
    {
        'name': 'PC Gamer News',
        'url': 'https://www.pcgamer.com/feeds',
        'priority_weight': 8,
    },
]


async def add_gaming_feeds():
    """Add gaming RSS feeds to the database."""
    settings = Settings()
    
    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        echo=True,
    )
    
    # Create tables if they don't exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create session factory
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        for feed_data in GAMING_FEEDS:
            # Check if feed already exists
            from sqlalchemy import select
            stmt = select(FeedModel).where(FeedModel.name == feed_data['name'])
            result = await session.execute(stmt)
            existing_feed = result.scalar_one_or_none()
            
            if existing_feed:
                print(f"✓ Feed '{feed_data['name']}' already exists")
                continue
            
            # Create new feed
            feed = FeedModel(
                id=uuid4(),
                name=feed_data['name'],
                url=feed_data['url'],
                priority_weight=feed_data['priority_weight'],
                enabled=True,
                last_fetch_at=datetime.utcnow(),
                last_fetch_success=True,
                consecutive_failures=0,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            
            session.add(feed)
            print(f"+ Added feed: {feed_data['name']}")
        
        await session.commit()
        print("\n✓ All gaming feeds have been added successfully!")
    
    await engine.dispose()


if __name__ == '__main__':
    asyncio.run(add_gaming_feeds())
