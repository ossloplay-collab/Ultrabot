"""Application settings using Pydantic v2."""

from typing import Optional

from pydantic import Field, SecretStr, field_validator, ConfigDict
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        json_file=None,
    )

    # Application
    app_name: str = "Ultrabot"
    app_version: str = "1.0.0"
    environment: str = Field(default="development", pattern="^(development|staging|production)$")
    log_level: str = Field(default="INFO", pattern="^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$")
    debug: bool = False

    # Telegram
    telegram_token: SecretStr = Field(default=SecretStr("test_token"), description="Telegram bot token")
    telegram_channel_id: int = Field(default=-1001234567890, description="Target channel ID (negative for groups)")
    telegram_poll_timeout: int = Field(default=30, ge=1, le=600)

    # Yandex Translate API
    yandex_api_key: SecretStr = Field(default=SecretStr("test_key"), description="Yandex Cloud API key")
    yandex_folder_id: str = Field(default="", description="Yandex Cloud folder ID (optional)")
    translate_target_lang: str = Field(default="ru", pattern="^[a-z]{2}$")
    translate_source_lang: str = Field(default="en", pattern="^[a-z]{2}$")

    # Database
    database_url: str = Field(
        default="postgresql+psycopg://ultrabot:ultrabot_password@localhost:5432/ultrabot",
        description="PostgreSQL connection string: postgresql+psycopg://user:pass@host:5432/db",
    )
    database_pool_size: int = Field(default=5, ge=1, le=50)
    database_max_overflow: int = Field(default=10, ge=0, le=100)
    database_pool_pre_ping: bool = Field(default=True)

    # Redis
    redis_url: str = Field(
        default="redis://localhost:6379/0",
        description="Redis connection string: redis://host:6379/db",
    )
    redis_ttl_translation: int = Field(default=3600, ge=60)
    redis_ttl_feed_response: int = Field(default=300, ge=60)
    redis_ttl_media_metadata: int = Field(default=86400, ge=3600)

    # RSS Feeds
    rss_check_interval: int = Field(default=300, ge=60, le=3600, description="Seconds between RSS checks")
    rss_max_age: int = Field(default=3600, ge=300, le=86400, description="Max age of news in seconds")
    rss_timeout: int = Field(default=15, ge=5, le=60, description="RSS fetch timeout")
    rss_user_agent: str = Field(
        default="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        description="User-Agent for HTTP requests",
    )
    rss_parallel_fetches: int = Field(default=5, ge=1, le=20, description="Parallel RSS fetch tasks")

    # Content Processing
    min_score_threshold: int = Field(default=8, ge=0, le=100, description="Minimum score to publish")
    extract_full_content: bool = Field(default=True, description="Extract full article text")
    content_extraction_timeout: int = Field(default=10, ge=5, le=30)
    max_images_per_post: int = Field(default=5, ge=1, le=10)
    max_hashtags_per_post: int = Field(default=10, ge=1, le=30)

    # Publication Queue
    publish_delay: int = Field(default=600, ge=60, le=3600, description="Delay between publications (seconds)")
    publish_delay_jitter: float = Field(default=0.2, ge=0.0, le=0.5, description="Jitter percentage")
    queue_max_size: int = Field(default=1000, ge=10, le=10000)
    queue_retry_max_attempts: int = Field(default=3, ge=1, le=10)
    queue_retry_backoff_base: float = Field(default=2.0, ge=1.0, le=10.0)
    dead_letter_queue_enabled: bool = Field(default=True)

    # Deduplication
    dedup_hash_algorithm: str = Field(default="md5", pattern="^(md5|sha256)$")
    dedup_content_prefix_len: int = Field(default=500, ge=100, le=2000)
    dedup_auto_cleanup_days: int = Field(default=7, ge=1, le=90)

    # External Integration
    circuit_breaker_failure_threshold: int = Field(default=5, ge=3, le=20)
    circuit_breaker_recovery_timeout: int = Field(default=60, ge=10, le=600)
    request_timeout: int = Field(default=30, ge=5, le=120)
    request_max_retries: int = Field(default=3, ge=1, le=10)

    # Prometheus Metrics
    metrics_enabled: bool = Field(default=True)
    metrics_port: int = Field(default=9090, ge=1024, le=65535)
    metrics_namespace: str = Field(default="ultrabot")

    # Web API
    api_enabled: bool = Field(default=True)
    api_host: str = Field(default="0.0.0.0")
    api_port: int = Field(default=8000, ge=1024, le=65535)
    api_workers: int = Field(default=2, ge=1, le=16)

    # Security
    allowed_hosts: list[str] = Field(default=["localhost", "127.0.0.1"])
    cors_enabled: bool = Field(default=False)
    cors_origins: list[str] = Field(default=[])

    # Logging
    log_format: str = Field(default="json", pattern="^(json|text)$")
    log_to_stdout: bool = Field(default=True)
    log_to_file: bool = Field(default=False)
    log_file_path: str = Field(default="logs/ultrabot.log")
    log_file_max_bytes: int = Field(default=10485760, ge=1048576)
    log_file_backup_count: int = Field(default=5, ge=1, le=20)

    # Graceful Shutdown
    shutdown_timeout: int = Field(default=30, ge=5, le=120, description="Grace period for shutdown")

    @field_validator("telegram_channel_id", mode="before")
    @classmethod
    def validate_channel_id(cls, v) -> int:
        """Validate Telegram channel ID (must be negative for groups)."""
        if isinstance(v, int):
            return v
        if isinstance(v, str):
            try:
                return int(v)
            except ValueError:
                # If it's a username like @channel, use default
                return -1001234567890
        raise ValueError("Channel ID must be integer or string")

    @field_validator("allowed_hosts", mode="before")
    @classmethod
    def parse_allowed_hosts(cls, v) -> list[str]:
        """Parse allowed_hosts from string or list."""
        # Handle None, empty, or missing values
        if v is None or v == "":
            return ["localhost", "127.0.0.1"]
        if isinstance(v, str):
            if not v.strip():
                return ["localhost", "127.0.0.1"]
            # Skip JSON parsing, just split by comma
            return [host.strip() for host in v.split(",") if host.strip()]
        if isinstance(v, list):
            return [h for h in v if h]
        return ["localhost", "127.0.0.1"]

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, v) -> list[str]:
        """Parse CORS origins from string or list."""
        # Handle None, empty, or missing values
        if v is None or v == "":
            return []
        if isinstance(v, str):
            if not v.strip():
                return []
            # Skip JSON parsing, just split by comma
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        if isinstance(v, list):
            return [o for o in v if o]
        return []


def get_settings() -> Settings:
    """Get application settings singleton."""
    return Settings()  # type: ignore
