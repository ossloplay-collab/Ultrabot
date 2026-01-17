# 🔧 Настройка .env на Windows

## ❌ Проблема

Бот не запускается с ошибкой:
```
TokenValidationError: Token is invalid!
```

**Причина:** Файл `.env` не существует или TELEGRAM_TOKEN не установлен.

## ✅ Решение

### Шаг 1: Получить Telegram Bot Token

1. Открыть Telegram, найти **@BotFather**
2. Отправить команду `/start`
3. Отправить `/newbot`
4. Дать имя боту (например: "Ultrabot")
5. Дать username боту (должен быть уникален, например: "ultrabot_gaming_bot")
6. **BotFather выдаст токен вроде:**
   ```
   123456789:ABCDEfghIjklmnoPqrst_uvwxyz1234567
   ```
7. **Скопировать этот токен!**

### Шаг 2: Получить ID Telegram Канала

1. Создать приватный канал в Telegram (если ещё нет)
2. Добавить своего бота (@BotFather gave username) в канал как администратора
3. Отправить любое сообщение в канал
4. Открыть: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
   - Заменить `<YOUR_TOKEN>` на полученный токен
5. Найти в JSON `chat.id` - это ID канала (отрицательное число, например: `-1001234567890`)
6. **Скопировать этот ID!**

### Шаг 3: Отредактировать .env файл

1. Открыть файл `.env` в редакторе (Notepad, VS Code, etc.)
2. Найти строки:
   ```
   TELEGRAM_TOKEN=your_telegram_bot_token_here
   TELEGRAM_CHANNEL_ID=-1001234567890
   ```
3. Заменить на:
   ```
   TELEGRAM_TOKEN=123456789:ABCDEfghIjklmnoPqrst_uvwxyz1234567
   TELEGRAM_CHANNEL_ID=-1001234567890
   ```
4. Сохранить файл

### Шаг 4: (Опционально) Настроить Yandex Translate

Если хочешь автоматический перевод новостей на русский:

1. Создать аккаунт на https://yandex.cloud
2. Создать API ключ в Yandex Cloud
3. Получить Folder ID
4. В `.env` заменить:
   ```
   YANDEX_API_KEY=ваш_api_ключ
   YANDEX_FOLDER_ID=ваш_folder_id
   ```

**Если не будешь настраивать Yandex** - новости просто не будут переводиться, но всё остальное будет работать.

### Шаг 5: Перезапустить Docker

На Windows PowerShell:

```powershell
# Перестроить образ с новым .env
docker-compose down
docker-compose up -d --build

# Подождать 10 секунд
Start-Sleep -Seconds 10

# Проверить логи
docker-compose logs --tail=50 bot
```

### Шаг 6: Проверить что бот запустился

В логах должно быть:
```
Feed processing background task started
✅ Application started successfully
Starting feed processing loop
```

Если видишь `Feed processing loop` - **ВСЁ РАБОТАЕТ!** 🎉

## 📋 Типичные Ошибки

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `TokenValidationError: Token is invalid!` | Токен неверный или отсутствует | Проверить TELEGRAM_TOKEN в .env |
| `Connection refused to postgres` | .env говорит на localhost вместо postgres | Убедиться что DATABASE_URL использует `postgres` вместо `localhost` |
| `Redis connection refused` | Redis не доступен | Убедиться что REDIS_URL использует `redis` вместо `localhost` |
| `BOT_COMMAND_SCOPE_DEFAULT` ошибка | BotFather токен протух | Получить новый токен у @BotFather |

## 🎯 Полный Checklist

- [ ] Получил Telegram bot token от @BotFather
- [ ] Получил Telegram channel ID
- [ ] Создал `.env` файл (скопировал из `.env.example`)
- [ ] Отредактировал TELEGRAM_TOKEN в `.env`
- [ ] Отредактировал TELEGRAM_CHANNEL_ID в `.env`
- [ ] Запустил `docker-compose down && docker-compose up -d --build`
- [ ] Проверил логи `docker-compose logs bot`
- [ ] Вижу "Feed processing loop started" в логах
- [ ] Бот начал собирать новости через 60 секунд

## 🚀 Быстрый Старт

```powershell
# Просто выполни эти команды по очереди:

# 1. Отредактируй .env и сохрани
notepad .env

# 2. Перезапусти Docker
docker-compose down
docker-compose up -d --build

# 3. Подожди загрузки
Start-Sleep -Seconds 10

# 4. Проверь логи
docker-compose logs -f bot

# 5. Жди 60 секунд и смотри "Starting feed processing cycle..."
```

После этого новости начнут собираться! ✅
