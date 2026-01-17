# ⚡ Быстрый старт на Windows (5 минут)

## 🚀 Команды для копирования

### 1. Открой PowerShell

Нажми: **Win+X** → выбери **PowerShell**

### 2. Перейди в папку проекта

```powershell
cd C:\path\to\Ultrabot
```

### 3. Создай файл .env

```powershell
@'
TELEGRAM_TOKEN=твой_токен_здесь
TELEGRAM_CHANNEL_ID=твой_канал_id
YANDEX_API_KEY=твой_api_ключ
YANDEX_FOLDER_ID=твой_folder_id
DATABASE_URL=postgresql+asyncpg://ultrabot:ultrabot@localhost:5432/ultrabot
REDIS_URL=redis://localhost:6379/0
DEBUG=false
LOG_LEVEL=INFO
'@ | Out-File -Encoding UTF8 .env
```

### 4. Запусти контейнеры Docker

```powershell
docker-compose up -d
```

**Жди 2-3 минуты...**

### 5. Проверь статус

```powershell
docker-compose ps
```

### 6. Добавь фиды про Доту

```powershell
python add_dota_feeds.py
```

### 7. Проверь результат

```powershell
docker-compose logs -f ultrabot-bot
```

---

## 📞 Если что-то не работает

Смотри полное руководство:
```powershell
cat WINDOWS_SETUP_GUIDE_RU.md
```

---

## 🛑 Останови бота

```powershell
docker-compose down
```

Готово! 🎉
