#!/usr/bin/env python3
"""Script to add Dota 2 gaming RSS feeds to the database."""

import asyncio
from datetime import datetime
from uuid import uuid4

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from src.infrastructure.database.models import Base, FeedModel
from src.core.settings import Settings


DOTA_FEEDS = [
    {
        'name': 'Dota 2 Official',
        'url': 'https://www.dota2.com/news/updates/feed',
        'priority_weight': 10,
    },
    {
        'name': 'Dotabuff News',
        'url': 'https://www.dotabuff.com/articles',
        'priority_weight': 8,
    },
    {
        'name': 'Liquipedia Dota 2',
        'url': 'https://liquipedia.net/dota2/api.php',
        'priority_weight': 9,
    },
    {
        'name': 'Pro Dota 2 News',
        'url': 'https://esportsobserver.com/dota-2/',
        'priority_weight': 7,
    },
    {
        'name': 'TrueGaming Dota',
        'url': 'https://www.truegaming.net/news',
        'priority_weight': 7,
    },
]


async def add_dota_feeds():
    """Add Dota 2 specific RSS feeds to the database."""
    print("🎮 Adding Dota 2 RSS feeds...\n")
    
    settings = Settings()
    
    engine = create_async_engine(
        settings.database_url,
        echo=False,
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    added_count = 0
    existing_count = 0
    
    async with async_session() as session:
        for feed_data in DOTA_FEEDS:
            stmt = select(FeedModel).where(FeedModel.name == feed_data['name'])
            result = await session.execute(stmt)
            existing_feed = result.scalar_one_or_none()
            
            if existing_feed:
                print(f"✓ {feed_data['name']} - уже существует")
                existing_count += 1
                continue
            
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
            print(f"+ {feed_data['name']} - добавлен")
            added_count += 1
        
        if added_count > 0:
            await session.commit()
    
    print(f"\n✅ Готово! Добавлено: {added_count}, уже было: {existing_count}")
    
    await engine.dispose()


if __name__ == '__main__':
    asyncio.run(add_dota_feeds())
