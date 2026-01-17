# 🔧 ФИНАЛЬНАЯ НАСТРОЙКА: Добавить Telegram Bot Token

## ⚠️ ВАЖНО

Бот требует **реальный Telegram bot token** для запуска. Без него бот не сможет стартовать!

Текущая ошибка:
```
TokenValidationError: Token is invalid!
```

Это **ОЖИДАЕМО** - нужно добавить настоящий токен.

## 📱 Шаг 1: Получить Token от @BotFather

### На Windows (Telegram Desktop или Web):

1. **Открыть Telegram**
2. **В поиске** найти `@BotFather`
3. **Открыть чат**
4. **Отправить:** `/newbot`
5. **Дать имя боту:** (например "Ultrabot")
6. **Дать username:** (например "ultrabot_gaming_bot", должен заканчиваться на `_bot`)
7. **Скопировать токен:**

```
Use this token to access the HTTP API:
123456789:ABCDEfghIjklmnoPqrst_uvwxyz1234567
```

**СКОПИРОВАТЬ ВЕСЬ ТОКЕН!** (от первой цифры до конца)

## 💾 Шаг 2: Добавить Token в .env

### На Windows PowerShell:

```powershell
# Способ 1: Отредактировать в блокноте
notepad .env

# В файле найти строку:
# TELEGRAM_TOKEN=your_telegram_bot_token_here

# Заменить на (вставить скопированный токен):
# TELEGRAM_TOKEN=123456789:ABCDEfghIjklmnoPqrst_uvwxyz1234567

# Нажать Ctrl+S (сохранить)
```

Или:

```powershell
# Способ 2: Через PowerShell (замени TOKEN на реальный)
$token = "123456789:ABCDEfghIjklmnoPqrst_uvwxyz1234567"
(Get-Content .env) -replace 'TELEGRAM_TOKEN=.*', "TELEGRAM_TOKEN=$token" | Set-Content .env
```

## 🚀 Шаг 3: Перезапустить Бот

```powershell
# Перезапустить контейнер бота
docker-compose restart bot

# Подождать 10 секунд
Start-Sleep -Seconds 10

# Проверить логи - должны быть БЕЗ ошибки TokenValidationError
docker-compose logs --tail=30 bot
```

## ✅ Что Должно Быть в Логах

**Если токен правильный:**

```
Database connected
Initializing caches...
Connected to Redis
Initializing external services...
Bot commands configured
Telegram bot started
External services initialized
✅ Application started successfully
Feed processing background task started
Starting feed processing loop (interval: 60s)
```

**Если токен неправильный:**

```
TokenValidationError: Token is invalid!
Failed to start application: Token is invalid!
```

## 📊 Проверить что Собирается

Через 60 секунд после запуска:

```powershell
# Проверить количество новостей
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) FROM news_items;"

# Должно быть > 0 если всё работает
```

## 🎯 Полный Процесс (Copy-Paste)

```powershell
# 1. Открыть .env
notepad .env

# 2. Найти TELEGRAM_TOKEN и заменить на реальный токен
#    (скопировать из @BotFather)

# 3. Сохранить (Ctrl+S) и закрыть

# 4. Перезапустить
docker-compose restart bot
Start-Sleep -Seconds 10

# 5. Проверить
docker-compose logs --tail=30 bot

# 6. Проверить новости (ждать 70 секунд после restart)
Start-Sleep -Seconds 70
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) FROM news_items;"
```

## 🆘 Если Не Работает

1. **Проверить что токен вставлен правильно:**
   ```powershell
   Select-String "TELEGRAM_TOKEN" .env
   ```

2. **Проверить что .env сохранён:**
   ```powershell
   Get-Content .env | Select-String "TELEGRAM_TOKEN"
   ```

3. **Полностью перезапустить:**
   ```powershell
   docker-compose down
   docker-compose up -d --build
   Start-Sleep -Seconds 20
   docker-compose logs bot
   ```

## ✨ Готово!

После добавления токена бот должен:
- ✅ Запуститься БЕЗ ошибок
- ✅ Подключиться к Telegram
- ✅ Начать собирать RSS новости каждые 60 секунд
- ✅ Публиковать их в твой Telegram канал

Жди новостей! 🎮🚀
