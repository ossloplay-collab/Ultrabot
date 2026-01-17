# Полная Диагностика RSS Лент - Тест Функционала

## 🎯 Проблема

Бот работает, но **новости не собираются**. Нужна полная проверка функционала.

## 🔍 Диагностика по шагам (Windows PowerShell)

### Шаг 1: Проверить таблицы в БД

```powershell
# Проверить существуют ли таблицы
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "\dt"

# Результат должен быть:
# 
#        List of relations
#  Schema |        Name        | Type  | Owner
# --------+--------------------+-------+---------
#  public | deduplication_cache | table | ultrabot
#  public | feeds              | table | ultrabot
#  public | metrics_logs       | table | ultrabot
#  public | news_items         | table | ultrabot
#  public | publications       | table | ultrabot
```

**Если таблиц нет** → запустить инициализацию БД:
```powershell
.\init-db.ps1
```

### Шаг 2: Проверить ленты в БД

```powershell
# Проверить что ленты добавлены
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT name, url, priority_weight, enabled FROM feeds ORDER BY priority_weight DESC;"

# Результат должен показать 5 лент:
# GameSpot, IGN, Kotaku, The Verge, PC Gamer
```

**Если лент нет** → добавить ленты:
```powershell
.\add_gaming_feeds.ps1
```

### Шаг 3: Количество собранных новостей

```powershell
# Проверить количество новостей
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) as total_news FROM news_items;"

# Если 0 → проблема в процессе сбора
# Если > 0 → проблема в публикации
```

### Шаг 4: Анализ собранных новостей

```powershell
# Посмотреть скоры новостей
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "
SELECT 
    score,
    COUNT(*) as count
FROM news_items
GROUP BY score
ORDER BY score DESC;
"

# Посмотреть среднего скора
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "
SELECT 
    COUNT(*) as total,
    ROUND(AVG(score), 2) as avg_score,
    MAX(score) as max_score,
    MIN(score) as min_score
FROM news_items;
"
```

### Шаг 5: Опубликованные новости

```powershell
# Проверить опубликованные новости
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) as published FROM publications WHERE status = 'success';"

# Посмотреть статусы публикаций
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "
SELECT 
    status,
    COUNT(*) as count
FROM publications
GROUP BY status;
"
```

### Шаг 6: Логи бота

```powershell
# Смотреть логи в реальном времени
docker-compose logs -f bot

# Ищите:
# - "Connecting to database..."
# - "Processing feed..." - попытка обработать ленту
# - "Got X entries from..." - сколько статей найдено
# - "Error" - ошибки при обработке
```

### Шаг 7: Проверить конфиг бота

```powershell
# Посмотреть переменные окружения
docker-compose exec bot env | findstr /i "RSS_CHECK_INTERVAL MIN_SCORE"

# Должно быть примерно:
# RSS_CHECK_INTERVAL=300  (проверка каждые 5 минут)
# MIN_SCORE_THRESHOLD=8   (минимальная оценка для публикации)
```

### Шаг 8: Тестовый запрос к API

```powershell
# Если бот имеет API для обработки лент (если есть в коде)
# Попробовать ручной запрос:
curl http://localhost:8000/api/feeds/process

# Или через PowerShell:
$response = Invoke-WebRequest -Uri "http://localhost:8000/api/feeds/process" -Method POST
$response.Content
```

### Шаг 9: Проверить сетевые подключения

```powershell
# Проверить что контейнер может достучаться до RSS лент
docker-compose exec bot curl -v https://feeds.ign.com/ign/all

# Или для любого другого источника:
docker-compose exec bot curl -v https://www.gamespot.com/feeds/mix/
```

### Шаг 10: Проверить Telegram

```powershell
# Проверить токен бота
docker-compose exec bot env | findstr TELEGRAM_TOKEN

# Проверить канал
docker-compose exec bot env | findstr TELEGRAM_CHANNEL_ID
```

## 📊 Запустить Comprehensive Тест

Создан автоматический тест, который проверяет всё:

```powershell
# На Linux/macOS:
python -m pytest tests/test_rss_feeds_standalone.py -v -s

# На Windows (в PowerShell):
python -m pytest tests/test_rss_feeds_standalone.py -v -s
```

Тест проверяет:
1. ✅ Подключение к БД
2. ✅ Наличие лент в БД
3. ✅ Может ли бот достучаться до RSS лент
4. ✅ Парсинг новостей из лент
5. ✅ Скорирование новостей (какие баллы получают)
6. ✅ Количество новостей в БД
7. ✅ Дедупликация (повторяющиеся новости)
8. ✅ Распределение новостей по баллам

## 🚨 Частые Проблемы

### 1. "Таблицы не найдены"
**Решение:**
```powershell
.\init-db.ps1
```

### 2. "Нет лент в БД"
**Решение:**
```powershell
.\add_gaming_feeds.ps1
```

### 3. "Новостей 0, но бот работает"
**Причины:**
- RSS ленты недоступны (проверить интернет)
- Неверные URL лент
- Бот не запустил процесс сбора
- Все новости отфильтрованы по скору

**Решение:**
- Проверить логи: `docker-compose logs bot | findstr RSS`
- Проверить доступность лент из контейнера
- Понизить MIN_SCORE_THRESHOLD в .env
- Проверить RSS_CHECK_INTERVAL (может быть очень большой)

### 4. "Новости есть, но не публикуются"
**Причины:**
- Все новости имеют score < 8 (фильтруются)
- Ошибка в Telegram токене
- Телеграм канал не доступен

**Решение:**
```powershell
# Проверить скоры
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT AVG(score) FROM news_items;"

# Если < 8, понизить порог:
# Отредактировать .env: MIN_SCORE_THRESHOLD=5
# Перезапустить: docker-compose up -d bot
```

### 5. "Ошибка 404 на /health"
**Причина:** Endpoint /health не реализован

**Это нормально** - проверить `/docs` для доступных endpoints:
```
http://localhost:8000/docs
```

## ✅ Полный Чек-лист

- [ ] Таблицы созданы (`.\init-db.ps1`)
- [ ] Ленты добавлены (`.\add_gaming_feeds.ps1`)
- [ ] Бот запущен (`docker-compose logs bot`)
- [ ] Новости начали собираться (подождать 10-15 минут)
- [ ] Скоры >= 8 для публикации
- [ ] Telegram токен валиден
- [ ] Telegram канал доступен

## 📝 Команды для Windows PowerShell

```powershell
# Запустить всё с начала:
.\init-db.ps1
.\add_gaming_feeds.ps1

# Мониторить логи:
docker-compose logs -f bot

# Проверить статус:
docker-compose ps

# Перезапустить бот:
docker-compose restart bot

# Новый запуск с очисткой:
docker-compose down
docker-compose up -d
```

## 🎯 Ожидаемое Поведение

1. **t=0:** Запуск бота - вывод инициализации
2. **t=300s (5 мин):** Первый сбор RSS лент
3. **t=310s:** Появляются первые новости в БД (news_items)
4. **t=600s (10 мин):** Начинают публиковаться новости в Telegram
5. **Каждые 300s:** Повторяется проверка лент

Если этого не происходит - смотрите раздел "Частые Проблемы"
