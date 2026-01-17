# 📖 Полное руководство: Ultrabot на Windows

## 📋 Оглавление
1. [Требования](#требования)
2. [Установка зависимостей](#установка-зависимостей)
3. [Получение ключей](#получение-ключей)
4. [Конфигурация](#конфигурация)
5. [Запуск бота](#запуск-бота)
6. [Добавление новостей про Доту](#добавление-новостей-про-доту)
7. [Мониторинг](#мониторинг)
8. [Решение проблем](#решение-проблем)

---

## 📋 Требования

- **Windows 10/11** (64-bit)
- **Docker Desktop** с WSL2
- **Git for Windows**
- **8GB+ RAM**
- **Интернет соединение**

---

## 🔧 Установка зависимостей

### 1. Git for Windows

1. Перейди на https://git-scm.com/download/win
2. Скачай инсталлер
3. Запусти и установи с параметрами по умолчанию
4. **Проверка**: Открой PowerShell (Win+X, выбери PowerShell)
   ```powershell
   git --version
   ```

### 2. Docker Desktop

1. Скачай с https://www.docker.com/products/docker-desktop
2. Запусти инсталлер
3. **Важно**: На этапе "Installation Options" отметь ✅ **"Use WSL 2 instead of Hyper-V"**
4. Перезагрузи компьютер
5. **Проверка** в PowerShell:
   ```powershell
   docker --version
   docker-compose --version
   ```

### 3. Python 3.11+ (опционально)

1. Скачай с https://www.python.org/downloads/
2. При установке **обязательно** отметь ✅ **"Add Python to PATH"**
3. **Проверка**:
   ```powershell
   python --version
   ```

---

## 📁 Клонирование репозитория

Открой PowerShell и выполни:

```powershell
# Переходишь в папку где хочешь хранить проект
cd C:\Users\YourUsername\Documents

# Клонируешь репозиторий
git clone https://github.com/kimakorr-gif/Ultrabot.git
cd Ultrabot

# Проверяешь структуру
dir
```

---

## 🔑 Получение необходимых ключей

### Telegram Bot Token

**Где получить:**
1. Открой Telegram
2. Найди **@BotFather** и напиши `/start`
3. Напиши `/newbot`
4. Дай имя боту (например: `MyUltrabotDota`)
5. Дай username (должен оканчиваться на `bot`, например: `my_ultrabot_dota_bot`)
6. BotFather пришлет токен:
   ```
   123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
   ```
   **Сохрани этот токен!** ✅

### Telegram Channel ID

**Где получить:**
1. Создай закрытый канал в Telegram (или используй существующий)
2. Добавь своего бота в администраторы канала
3. Отправь тестовое сообщение в канал
4. Открой https://web.telegram.org/ (выбери "Desktop")
5. Перейди в канал → посмотри URL в адресной строке
6. ID будет вида `-100...` (например: `-1001234567890`)
   **Сохрани ID!** ✅

**Или используй скрипт:**
```powershell
# Создай файл test_bot.py:
@'
import asyncio
from telegram import Bot

async def get_updates():
    # Замени на свой токен
    bot = Bot(token='123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11')
    updates = await bot.get_updates()
    for update in updates:
        print(f'Chat ID: {update.message.chat_id}')

asyncio.run(get_updates())
'@ | Out-File test_bot.py

python test_bot.py
```

### Yandex Translation API Key

**Где получить:**
1. Перейди на https://cloud.yandex.com/
2. Создай аккаунт или войди
3. Создай новый проект
4. Перейди в **IAM** → **Service Accounts**
5. Создай service account
6. Создай API ключ
7. **Сохрани ключ и Folder ID!** ✅

---

## 📝 Конфигурация (.env файл)

### Создание файла .env

Открой **Notepad** (Блокнот):
- Win+R → напиши `notepad` → Enter

### Содержимое .env

Скопируй и замени значения на свои:

```env
# ============ Telegram Configuration ============
TELEGRAM_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHANNEL_ID=-1001234567890
TELEGRAM_RETRY_ATTEMPTS=3
TELEGRAM_TIMEOUT=30

# ============ Yandex Translation ============
YANDEX_API_KEY=your_api_key_here
YANDEX_FOLDER_ID=your_folder_id_here

# ============ Database ============
DATABASE_URL=postgresql+asyncpg://ultrabot:ultrabot@localhost:5432/ultrabot
REDIS_URL=redis://localhost:6379/0

# ============ Application Settings ============
DEBUG=false
LOG_LEVEL=INFO
FETCH_INTERVAL=300
```

### Сохранение файла

1. File → Save As
2. Выбери папку проекта `C:\path\to\Ultrabot`
3. **Имя файла**: `.env` (именно с точкой в начале!)
4. **Тип**: "All Files (*.*)"
5. Нажми Save

---

## 🚀 Запуск бота

### Шаг 1: Запуск контейнеров Docker

Открой PowerShell в папке проекта:

```powershell
# Переходишь в папку проекта
cd C:\path\to\Ultrabot

# Запускаешь контейнеры
docker-compose up -d
```

**Что происходит:**
- Загружаются образы PostgreSQL, Redis, Ultrabot
- Создается база данных
- Запускаются все сервисы

**Первый раз может занять 5-10 минут!**

### Шаг 2: Проверка статуса

```powershell
docker-compose ps
```

**Ожидаемый вывод** (все должны быть в статусе `Up`):
```
NAME              IMAGE           STATUS
ultrabot-postgres-1    postgres:15    Up 2 minutes
ultrabot-redis-1       redis:7        Up 2 minutes
ultrabot-bot-1         ultrabot:dev   Up 1 minute
```

### Шаг 3: Проверка логов

```powershell
# Просмотр логов бота
docker-compose logs ultrabot-bot

# Или в реальном времени (Ctrl+C для выхода)
docker-compose logs -f ultrabot-bot
```

---

## 📰 Добавление новостей про Доту

### Вариант 1: Python скрипт (Рекомендуется)

#### 1.1 Создание скрипта

Открой PowerShell и создай скрипт:

```powershell
@'
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
        "name": "Dota 2 Official",
        "url": "https://www.dota2.com/news/updates/feed",
        "priority_weight": 10,
    },
    {
        "name": "Dotabuff News",
        "url": "https://www.dotabuff.com/articles",
        "priority_weight": 8,
    },
    {
        "name": "Liquipedia Dota 2",
        "url": "https://liquipedia.net/dota2/api.php",
        "priority_weight": 9,
    },
    {
        "name": "Pro Dota 2 News",
        "url": "https://esportsobserver.com/dota-2/",
        "priority_weight": 7,
    },
    {
        "name": "TrueGaming Dota",
        "url": "https://www.truegaming.net/news",
        "priority_weight": 7,
    },
]

async def add_dota_feeds():
    print("🎮 Adding Dota 2 RSS feeds...\n")
    
    settings = Settings()
    engine = create_async_engine(settings.database_url, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        for feed_data in DOTA_FEEDS:
            stmt = select(FeedModel).where(FeedModel.name == feed_data["name"])
            result = await session.execute(stmt)
            
            if result.scalar_one_or_none():
                print(f"✓ {feed_data['name']} - уже существует")
                continue
            
            feed = FeedModel(
                id=uuid4(),
                name=feed_data["name"],
                url=feed_data["url"],
                priority_weight=feed_data["priority_weight"],
                enabled=True,
                last_fetch_at=datetime.utcnow(),
                last_fetch_success=True,
                consecutive_failures=0,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            
            session.add(feed)
            print(f"+ {feed_data['name']} - добавлен")
        
        await session.commit()
        print("\n✅ Все фиды про Доту добавлены!")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(add_dota_feeds())
'@ | Out-File -Encoding UTF8 add_dota_feeds.py
```

#### 1.2 Запуск скрипта

```powershell
# Убедись, что бот запущен в Docker
docker-compose ps

# Запусти скрипт
python add_dota_feeds.py
```

**Ожидаемый вывод:**
```
🎮 Adding Dota 2 RSS feeds...

+ Dota 2 Official - добавлен
+ Dotabuff News - добавлен
+ Liquipedia Dota 2 - добавлен
+ Pro Dota 2 News - добавлен
+ TrueGaming Dota - добавлен

✅ Все фиды про Доту добавлены!
```

### Вариант 2: Через SQL команду

#### 2.1 Подключение к БД

```powershell
docker-compose exec postgres psql -U ultrabot -d ultrabot
```

#### 2.2 Выполнение SQL

В интерпретаторе psql введи:

```sql
INSERT INTO feeds (id, name, url, enabled, priority_weight, last_fetch_at, last_fetch_success, consecutive_failures, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'Dota 2 Official', 'https://www.dota2.com/news/updates/feed', true, 10, now(), true, 0, now(), now()),
  (gen_random_uuid(), 'Dotabuff News', 'https://www.dotabuff.com/articles', true, 8, now(), true, 0, now(), now()),
  (gen_random_uuid(), 'Liquipedia Dota 2', 'https://liquipedia.net/dota2', true, 9, now(), true, 0, now(), now()),
  (gen_random_uuid(), 'Pro Dota 2 News', 'https://esportsobserver.com/dota-2/', true, 7, now(), true, 0, now(), now()),
  (gen_random_uuid(), 'TrueGaming Dota', 'https://www.truegaming.net/news', true, 7, now(), true, 0, now(), now());
```

#### 2.3 Выход из БД

```sql
\q
```

---

## 🔍 Мониторинг

### Просмотр всех добавленных фидов

```powershell
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT name, url, priority_weight, enabled FROM feeds;"
```

### Просмотр новостей про Доту

```powershell
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT title_en, score FROM news_items LIMIT 10;"
```

### Просмотр логов в реальном времени

```powershell
docker-compose logs -f ultrabot-bot

# Для выхода нажми Ctrl+C
```

### Проверка здоровья приложения

```powershell
curl http://localhost:8000/health
```

Должен ответить:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

---

## ⚠️ Решение проблем

### ❌ Docker контейнеры не запускаются

**Решение:**
```powershell
# Останови контейнеры
docker-compose down

# Удали объемы (осторожно, потеряются данные!)
docker-compose down -v

# Запусти заново
docker-compose up -d

# Проверь логи
docker-compose logs
```

### ❌ Бот не отправляет сообщения в Telegram

**Проверь:**
1. Токен правильный в `.env`
2. Канал ID правильный
3. Бот администратор в канале
4. Интернет соединение работает

```powershell
# Посмотри ошибки
docker-compose logs ultrabot-bot | grep -i telegram
```

### ❌ Новости не появляются

**Проверь:**
1. Фиды добавлены в БД
   ```powershell
   docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) FROM feeds;"
   ```

2. У фидов `enabled=true`
   ```powershell
   docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT name, enabled FROM feeds;"
   ```

3. RSS URL доступны (попробуй открыть в браузере)

### ❌ "Connection refused" при подключении к БД

**Решение:**
```powershell
# Убедись, что PostgreSQL запущен
docker-compose ps postgres

# Если не запущен, перезапусти
docker-compose restart postgres
```

### ❌ Ошибка: "database does not exist"

**Решение:**
```powershell
# Создай БД вручную
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE ultrabot;"

# Или перезапусти все
docker-compose down -v
docker-compose up -d
```

---

## 🛑 Остановка и запуск

### Остановить контейнеры (данные сохранятся)
```powershell
docker-compose down
```

### Снова запустить
```powershell
docker-compose up -d
```

### Полностью удалить (включая данные)
```powershell
docker-compose down -v
```

---

## 📚 Дополнительные команды

### Просмотр всех новостей
```powershell
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT id, title_en, score, is_published FROM news_items ORDER BY created_at DESC LIMIT 20;"
```

### Удалить все фиды про Доту
```powershell
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "DELETE FROM feeds WHERE name LIKE '%Dota%';"
```

### Обновить приложение из GitHub
```powershell
git pull origin main
docker-compose build
docker-compose down
docker-compose up -d
```

### Экспортировать данные БД (резервная копия)
```powershell
docker-compose exec postgres pg_dump -U ultrabot ultrabot > backup.sql
```

### Импортировать данные в БД
```powershell
docker-compose exec -T postgres psql -U ultrabot ultrabot < backup.sql
```

---

## ✅ Что дальше?

1. **Перейди в Telegram канал** → посмотри новые сообщения про Доту ✅
2. **Настрой расписание обработки** → отредактируй `FETCH_INTERVAL` в `.env`
3. **Добавь фильтры** → смотри `src/domain/services/scoring_service.py`
4. **Включи мониторинг** → смотри `docs/MONITORING.md`

---

## 📞 Помощь

- Полная документация: [GETTING_STARTED.md](GETTING_STARTED.md)
- Архитектура: [ARCHITECTURE.md](ARCHITECTURE.md)
- API документация: [docs/API.md](docs/API.md)
- Развертывание: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

Удачи! 🚀🎮
