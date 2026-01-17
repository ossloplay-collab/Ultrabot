"""Global status test - shows RSS feeds, news statistics and database information."""

import asyncio
import pytest
from datetime import datetime
from sqlalchemy import create_engine, text, select, func
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from src.core.settings import Settings
from src.infrastructure.database.models import Base, FeedModel, NewsItemModel, PublicationModel


class TestGlobalStatus:
    """Global status and statistics test."""

    @pytest.mark.asyncio
    async def test_global_system_status(self):
        """
        Comprehensive global test showing:
        - Connected RSS feeds
        - Total news items viewed (created)
        - News items waiting for publication (unpublished)
        - News items stored in database (total)
        """
        print("\n" + "="*80)
        print(" "*20 + "🌍 ГЛОБАЛЬНЫЙ СТАТУС СИСТЕМЫ")
        print("="*80)
        
        settings = Settings()
        
        # Connect to database
        print("\n[1️⃣  ПОДКЛЮЧЕНИЕ К БД...]")
        try:
            engine = create_async_engine(
                settings.database_url,
                echo=False,
                pool_pre_ping=True,
            )
            async_session = sessionmaker(
                engine, class_=AsyncSession, expire_on_commit=False
            )
            
            async with engine.begin() as conn:
                await conn.run_sync(lambda c: None)
            print("✅ Подключение к БД установлено успешно")
        except Exception as e:
            print(f"❌ Ошибка подключения к БД: {e}")
            raise

        # Get statistics
        try:
            async with async_session() as session:
                print("\n[2️⃣  СБОР СТАТИСТИКИ...]")
                
                # 1. Get all connected RSS feeds
                print("\n┌─ RSS ЛЕНТЫ (Подключенные источники):")
                feeds_result = await session.execute(
                    select(FeedModel).order_by(FeedModel.name)
                )
                feeds = feeds_result.scalars().all()
                
                print(f"│ Всего лент: {len(feeds)}")
                if feeds:
                    for i, feed in enumerate(feeds, 1):
                        status_icon = "✅" if feed.enabled else "❌"
                        last_fetch = feed.last_fetch_at.strftime("%Y-%m-%d %H:%M:%S") if feed.last_fetch_at else "N/A"
                        print(f"│  {i}. {status_icon} {feed.name}")
                        print(f"│     URL: {feed.url}")
                        print(f"│     Приоритет: {feed.priority_weight}")
                        print(f"│     Последний фетч: {last_fetch}")
                        print(f"│     Статус: {'Успех' if feed.last_fetch_success else 'Ошибка'}")
                        print(f"│     Ошибок подряд: {feed.consecutive_failures}")
                else:
                    print("│ ℹ️  Нет добавленных лент")
                print("└")
                
                # 2. Total news items (created/viewed)
                print("\n┌─ СТАТИСТИКА НОВОСТЕЙ:")
                total_news_result = await session.execute(
                    select(func.count(NewsItemModel.id))
                )
                total_news = total_news_result.scalar() or 0
                print(f"│ Всего новостей в БД: {total_news}")
                
                # 3. Unpublished news (waiting for publication)
                print("\n┌─ ОЖИДАЮТ ПУБЛИКАЦИЮ:")
                unpublished_result = await session.execute(
                    select(func.count(NewsItemModel.id))
                    .where(NewsItemModel.is_published == False)
                )
                unpublished_count = unpublished_result.scalar() or 0
                print(f"│ Новостей ожидают публикации: {unpublished_count}")
                
                # Get top unpublished by score
                top_unpublished_result = await session.execute(
                    select(NewsItemModel)
                    .where(NewsItemModel.is_published == False)
                    .order_by(NewsItemModel.score.desc())
                    .limit(5)
                )
                top_unpublished = top_unpublished_result.scalars().all()
                
                if top_unpublished:
                    print("│ Top 5 по рейтингу:")
                    for i, news in enumerate(top_unpublished, 1):
                        print(f"│  {i}. [{news.score} ⭐] {news.title_en[:60]}...")
                        print(f"│     Попыток публикации: {news.publication_attempts}")
                print("└")
                
                # 4. Published news
                print("\n┌─ ОПУБЛИКОВАНЫ:")
                published_result = await session.execute(
                    select(func.count(NewsItemModel.id))
                    .where(NewsItemModel.is_published == True)
                )
                published_count = published_result.scalar() or 0
                print(f"│ Опубликовано новостей: {published_count}")
                
                # Get recently published
                recent_published_result = await session.execute(
                    select(NewsItemModel)
                    .where(NewsItemModel.is_published == True)
                    .order_by(NewsItemModel.published_at.desc())
                    .limit(3)
                )
                recent_published = recent_published_result.scalars().all()
                
                if recent_published:
                    print("│ Последние опубликованные:")
                    for i, news in enumerate(recent_published, 1):
                        pub_date = news.published_at.strftime("%Y-%m-%d %H:%M:%S") if news.published_at else "N/A"
                        print(f"│  {i}. {news.title_en[:50]}...")
                        print(f"│     Опубликовано: {pub_date}")
                print("└")
                
                # 5. By source
                print("\n┌─ РАСПРЕДЕЛЕНИЕ ПО ИСТОЧНИКАМ:")
                sources_result = await session.execute(
                    select(NewsItemModel.source_name, func.count(NewsItemModel.id))
                    .group_by(NewsItemModel.source_name)
                    .order_by(func.count(NewsItemModel.id).desc())
                )
                sources = sources_result.all()
                
                if sources:
                    for i, (source_name, count) in enumerate(sources, 1):
                        print(f"│  {i}. {source_name}: {count} новостей")
                else:
                    print("│ ℹ️  Нет новостей в БД")
                print("└")
                
                # 6. Average score
                print("\n┌─ АНАЛИТИКА:")
                avg_score_result = await session.execute(
                    select(func.avg(NewsItemModel.score))
                    .where(NewsItemModel.score > 0)
                )
                avg_score = avg_score_result.scalar() or 0
                
                max_score_result = await session.execute(
                    select(func.max(NewsItemModel.score))
                )
                max_score = max_score_result.scalar() or 0
                
                min_score_result = await session.execute(
                    select(func.min(NewsItemModel.score))
                    .where(NewsItemModel.score > 0)
                )
                min_score = min_score_result.scalar() or 0
                
                print(f"│ Средний рейтинг: {avg_score:.1f} ⭐")
                print(f"│ Макс рейтинг: {max_score} ⭐")
                print(f"│ Мин рейтинг: {min_score} ⭐")
                
                # Success rate
                if total_news > 0:
                    published_rate = (published_count / total_news) * 100
                    print(f"│ Процент опубликованных: {published_rate:.1f}%")
                print("└")
                
                # 7. Database info
                print("\n┌─ ИНФОРМАЦИЯ О БД:")
                db_size_result = await session.execute(
                    text("""
                        SELECT 
                            pg_size_pretty(pg_database.datsize) as size
                        FROM pg_database
                        WHERE datname = 'ultrabot'
                    """)
                )
                db_info = db_size_result.fetchone()
                if db_info:
                    print(f"│ Размер БД: {db_info[0]}")
                
                # Tables info
                tables_result = await session.execute(
                    text("""
                        SELECT 
                            tablename,
                            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
                        FROM pg_tables
                        WHERE schemaname = 'public'
                        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
                    """)
                )
                tables_info = tables_result.fetchall()
                if tables_info:
                    print("│ Таблицы:")
                    for table_name, table_size in tables_info:
                        print(f"│  - {table_name}: {table_size}")
                print("└")
                
                # Summary
                print("\n" + "="*80)
                print("📊 ИТОГОВАЯ СВОДКА:")
                print("="*80)
                print(f"✅ RSS Лент подключено: {len(feeds)}")
                print(f"📥 Новостей обработано: {total_news}")
                print(f"⏳ Ожидают публикации: {unpublished_count}")
                print(f"✔️  Опубликовано: {published_count}")
                print(f"📊 Среднее качество: {avg_score:.1f}/100")
                print("="*80 + "\n")
                
        except Exception as e:
            print(f"\n❌ Ошибка при сборе статистики: {e}")
            raise
        finally:
            await engine.dispose()


# Standalone function for easy running
async def run_global_status_check():
    """Run global status check without pytest."""
    test = TestGlobalStatus()
    await test.test_global_system_status()


if __name__ == "__main__":
    # Can be run with: python -m pytest tests/test_global_status.py -v -s
    # Or with: python -c "from tests.test_global_status import run_global_status_check; import asyncio; asyncio.run(run_global_status_check())"
    pytest.main([__file__, "-v", "-s"])
