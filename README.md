# 🤖 Ultrabot - Gaming News Aggregator

[![Python 3.11+](https://img.shields.io/badge/Python-3.11%2B-blue)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)]()
[![Status: Production Ready](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)]()
[![Tests Passing](https://img.shields.io/badge/Tests-39%2F39%20Passing-brightgreen)]()

**Production-ready Telegram bot for aggregating gaming news from 50+ RSS feeds with intelligent filtering, translation, and publishing.**

[🚀 Quick Start](#-quick-start) • [📖 Full Guide](GETTING_STARTED.md) • [🏗️ Architecture](ARCHITECTURE.md) • [📚 Docs](docs/)

---

## ✨ Features

- **📰 Multi-Source Aggregation**: Monitor 50+ RSS feeds from gaming publications
- **🎮 Smart Filtering**: Keyword-based filtering (RPG, FPS, Strategy, Platform-specific)
- **🏆 Quality Scoring**: 3-tier keyword system + source weighting + freshness bonus
- **🌍 Translation**: Yandex API with proper noun preservation
- **♻️ Deduplication**: MD5-based automatic duplicate detection
- **📤 Auto-Publishing**: To Telegram with hashtags and media
- **🛡️ Resilience**: Circuit breaker, exponential backoff retry, error handling
- **📊 Monitoring**: Prometheus metrics (35+), Grafana dashboards
- **🐳 Containerized**: Docker + Docker Compose for quick setup
- **☸️ Scalable**: Kubernetes-ready with HPA
- **🔐 Secure**: No secrets in code, non-root containers, HTTPS-ready
- **⚡ Performant**: <30s per news, <512MB memory, <300MB Docker image

---

## 🚀 Quick Start

### 1️⃣ Clone & Install (Linux/macOS)
```bash
git clone https://github.com/kimakorr-gif/Ultrabot.git
cd Ultrabot
./install.sh
```

**Windows Users**: Run `install.bat` instead

### 2️⃣ Configure
```bash
# Edit configuration
nano .env

# Set your credentials:
TELEGRAM_TOKEN=your_bot_token
TELEGRAM_CHANNEL_ID=-1001234567890
YANDEX_API_KEY=your_api_key
```

### 3️⃣ Run
```bash
# Start services
docker-compose up -d

# Run application
make run

# Or with auto-reload (development)
make run-dev
```

**Done!** 🎉 App running at `http://localhost:8000`

---

## 📊 Check System Status

To view the current system state (RSS feeds, news statistics, database info):

```bash
# Quick status check
make status

# Or detailed pytest output
make test-global

# Or direct Python
python check_status.py
```

See [GLOBAL_TEST.md](GLOBAL_TEST.md) for detailed information about available metrics.
**Done!** 🎉 App running at `http://localhost:8000`