"""Main application entry point."""

import asyncio
import logging
import signal
from typing import Optional

from fastapi import FastAPI
from uvicorn import Server, Config

from src.core.logger import setup_logging, get_logger
from src.core.settings import get_settings
from src.core.metrics import SYSTEM_UPTIME
from src.infrastructure.cache.memory_cache import MemoryCache
from src.infrastructure.cache.redis_cache import RedisCache
from src.infrastructure.database.models import create_db_engine, Base
from src.infrastructure.external.rss_parser import FeedParserAdapter
from src.infrastructure.external.yandex_translator import YandexTranslatorAdapter
from src.infrastructure.external.telegram_client import TelegramClientAdapter
from src.presentation.web.health_api import router as health_router
from src.presentation.telegram.bot import TelegramBot
from src.presentation.telegram.handlers import router as telegram_router

logger = get_logger(__name__)


class Application:
    """Main application class."""

    def __init__(self) -> None:
        """Initialize application."""
        self.settings = get_settings()
        setup_logging(self.settings)

        # Initialize FastAPI
        self.app = FastAPI(
            title="Ultrabot",
            version="1.0.0",
            description="Gaming News Aggregator",
        )

        # Add root endpoint
        @self.app.get("/")
        async def root():
            return {
                "name": "Ultrabot",
                "version": "1.0.0",
                "description": "Gaming News Aggregator Bot",
                "endpoints": {
                    "api": "/api/",
                    "health": "/api/health",
                    "ready": "/api/ready",
                    "metrics": "/api/metrics",
                    "stats": "/api/stats",
                    "docs": "/docs",
                    "redoc": "/redoc",
                }
            }

        # Add routers
        self.app.include_router(health_router)

        # Initialize components
        self.db_engine: Optional[any] = None
        self.redis_cache: Optional[RedisCache] = None
        self.memory_cache: Optional[MemoryCache] = None
        self.rss_parser: Optional[FeedParserAdapter] = None
        self.translator: Optional[YandexTranslatorAdapter] = None
        self.telegram_client: Optional[TelegramClientAdapter] = None
        self.telegram_bot: Optional[TelegramBot] = None
        self.feed_processing_task: Optional[asyncio.Task] = None

        # Setup shutdown hooks
        self.app.add_event_handler("shutdown", self.shutdown)

        logger.info(f"Application initialized (environment={self.settings.environment})")

    async def startup(self) -> None:
        """Initialize application resources."""
        try:
            logger.info("Starting application...")

            # Initialize database
            logger.info("Connecting to database...")
            self.db_engine = create_db_engine(str(self.settings.database_url))
            # Create tables (ignore if they already exist)
            try:
                Base.metadata.create_all(self.db_engine)
            except Exception as e:
                logger.warning(f"Database tables may already exist: {e}")
            logger.info("Database connected")

            # Initialize caches
            logger.info("Initializing caches...")
            self.memory_cache = MemoryCache(max_size=1000)
            
            if self.settings.redis_url:
                self.redis_cache = RedisCache(str(self.settings.redis_url))
                await self.redis_cache.connect()
            logger.info("Caches initialized")

            # Initialize external services
            logger.info("Initializing external services...")
            self.rss_parser = FeedParserAdapter(
                user_agent=self.settings.rss_user_agent,
                timeout=self.settings.rss_timeout,
            )

            self.translator = YandexTranslatorAdapter(
                api_key=self.settings.yandex_api_key.get_secret_value(),
                folder_id=self.settings.yandex_folder_id,
            )

            self.telegram_client = TelegramClientAdapter(
                token=self.settings.telegram_token.get_secret_value(),
            )

            if self.settings.telegram_token:
                self.telegram_bot = TelegramBot(
                    token=self.settings.telegram_token.get_secret_value(),
                )
                await self.telegram_bot.start()

            logger.info("External services initialized")

            # Record startup time
            import time
            SYSTEM_UPTIME.set_to_current_time()

            # Start background feed processing task
            self.feed_processing_task = asyncio.create_task(self._feed_processing_loop())
            logger.info("Feed processing background task started")

            logger.info("✅ Application started successfully")

        except Exception as e:
            logger.error(f"❌ Failed to start application: {e}")
            raise

    async def shutdown(self) -> None:
        """Cleanup application resources."""
        logger.info("Shutting down application...")

        try:
            # Cancel feed processing task
            if self.feed_processing_task and not self.feed_processing_task.done():
                self.feed_processing_task.cancel()
                try:
                    await self.feed_processing_task
                except asyncio.CancelledError:
                    logger.info("Feed processing task cancelled")

            # Close database
            if self.db_engine:
                self.db_engine.dispose()
                logger.info("Database closed")

            # Close Redis
            if self.redis_cache:
                await self.redis_cache.disconnect()
                logger.info("Redis closed")

            # Close Telegram bot
            if self.telegram_bot:
                await self.telegram_bot.stop()
                logger.info("Telegram bot stopped")

            # Close Telegram client
            if self.telegram_client:
                await self.telegram_client.close()
                logger.info("Telegram client closed")

            logger.info("✅ Application shut down gracefully")

        except Exception as e:
            logger.error(f"Error during shutdown: {e}")

    async def _feed_processing_loop(self) -> None:
        """Background task for processing RSS feeds periodically."""
        import time
        
        logger.info(f"Starting feed processing loop (interval: {self.settings.rss_check_interval}s)")
        
        try:
            while True:
                try:
                    logger.info("Starting RSS feed collection cycle...")
                    start_time = time.time()
                    
                    # TODO: Implement actual feed processing
                    # This would call ProcessFeedsUseCase to collect and process feeds
                    # For now, just log that we're checking
                    logger.info("RSS feed collection cycle completed (no feeds processed yet - implementation pending)")
                    
                    duration = time.time() - start_time
                    logger.info(f"Feed processing cycle took {duration:.2f}s")
                    
                except Exception as e:
                    logger.error(f"Error in feed processing cycle: {e}", exc_info=True)
                
                # Wait for next cycle
                await asyncio.sleep(self.settings.rss_check_interval)
                
        except asyncio.CancelledError:
            logger.info("Feed processing loop cancelled")
            raise

    async def run(self) -> None:
        """Run the application."""
        await self.startup()

        # Run FastAPI server
        config = Config(
            app=self.app,
            host=self.settings.api_host,
            port=self.settings.api_port,
            workers=self.settings.api_workers,
            log_level=self.settings.log_level.lower(),
        )

        server = Server(config)

        # Handle signals
        loop = asyncio.get_event_loop()

        def handle_signal(signum, frame):
            logger.info(f"Received signal {signum}")
            loop.create_task(self.shutdown())

        signal.signal(signal.SIGTERM, handle_signal)
        signal.signal(signal.SIGINT, handle_signal)

        try:
            await server.serve()
        except Exception as e:
            logger.error(f"Server error: {e}")
        finally:
            await self.shutdown()


async def main() -> None:
    """Application entry point."""
    app_instance = Application()
    await app_instance.run()


# Create app instance for uvicorn
_app_instance = Application()
app = _app_instance.app


if __name__ == "__main__":
    asyncio.run(main())
