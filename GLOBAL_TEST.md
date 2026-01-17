# 🌍 Глобальный тест статуса системы

## Описание

Глобальный тест предоставляет полную информацию о состоянии системы Ultrabot:

### Что показывает тест:

1. **📡 Подключенные RSS ленты**
   - Список всех источников новостей
   - Статус каждой ленты (активна/неактивна)
   - Приоритет и вес
   - Время последней загрузки
   - Количество ошибок подряд

2. **📊 Статистика новостей**
   - Общее количество новостей в БД
   - Количество новостей, ожидающих публикации
   - Количество опубликованных новостей
   - Top 5 новостей по рейтингу (ожидающих публикации)

3. **🔝 Распределение по источникам**
   - Показывает количество новостей от каждого источника
   - Помогает найти наиболее активные ленты

4. **📈 Аналитика**
   - Средний рейтинг новостей
   - Максимальный и минимальный рейтинг
   - Процент опубликованных новостей

5. **🗄️ Информация о БД**
   - Размер базы данных
   - Размер каждой таблицы

## Запуск теста

### Способ 1: Через Make (рекомендуется)

```bash
make status
```

или для полного вывода с pytest:

```bash
make test-global
```

### Способ 2: Напрямую Python

```bash
python check_status.py
```

### Способ 3: Через pytest

```bash
python -m pytest tests/test_global_status.py -v -s
```

### Способ 4: PowerShell на Windows

```powershell
.\check_status.ps1
```

## Пример вывода

```
================================================================================
                    🌍 ГЛОБАЛЬНЫЙ СТАТУС СИСТЕМЫ
================================================================================

[1️⃣  ПОДКЛЮЧЕНИЕ К БД...]
✅ Подключение к БД установлено успешно

[2️⃣  СБОР СТАТИСТИКИ...]

┌─ RSS ЛЕНТЫ (Подключенные источники):
│ Всего лент: 3
│  1. ✅ GameNews Daily
│     URL: https://www.gamenewsdaily.com/feed
│     Приоритет: 8
│     Последний фетч: 2026-01-17 14:30:22
│     Статус: Успех
│     Ошибок подряд: 0
│  2. ✅ Dota2 Official
│     URL: https://dota2.com/news
│     Приоритет: 10
│     Последний фетч: 2026-01-17 14:25:15
│     Статус: Успех
│     Ошибок подряд: 0
│  3. ✅ Twitch Gaming
│     URL: https://www.twitch.tv/gaming/feed
│     Приоритет: 5
│     Последний фетч: 2026-01-17 13:45:10
│     Статус: Успех
│     Ошибок подряд: 0
└

┌─ СТАТИСТИКА НОВОСТЕЙ:
│ Всего новостей в БД: 342
└

┌─ ОЖИДАЮТ ПУБЛИКАЦИЮ:
│ Новостей ожидают публикации: 45
│ Top 5 по рейтингу:
│  1. [92 ⭐] New Counter-Strike 2 Tournament Announced with $1M Prize...
│     Попыток публикации: 0
│  2. [88 ⭐] Valorant Patch 8.03: Major Balance Changes...
│     Попыток публикации: 0
│  3. [85 ⭐] League of Legends World Championship 2026 Dates...
│     Попыток публикации: 1
│  4. [82 ⭐] Steam Winter Sale: Best Indie Games...
│     Попыток публикации: 0
│  5. [80 ⭐] Elden Ring DLC Release Date Confirmed...
│     Попыток публикации: 0
└

┌─ ОПУБЛИКОВАНЫ:
│ Опубликовано новостей: 297
│ Последние опубликованные:
│  1. Breaking: New GPU Release Could Revolutionize Gaming...
│     Опубликовано: 2026-01-17 14:20:15
│  2. Esports Tournament Schedule for February 2026...
│     Опубликовано: 2026-01-17 13:55:42
│  3. Game Developer Interview: The Future of Gaming...
│     Опубликовано: 2026-01-17 12:30:18
└

┌─ РАСПРЕДЕЛЕНИЕ ПО ИСТОЧНИКАМ:
│  1. GameNews Daily: 156 новостей
│  2. Dota2 Official: 120 новостей
│  3. Twitch Gaming: 66 новостей
└

┌─ АНАЛИТИКА:
│ Средний рейтинг: 72.5 ⭐
│ Макс рейтинг: 98 ⭐
│ Мин рейтинг: 15 ⭐
│ Процент опубликованных: 86.8%
└

┌─ ИНФОРМАЦИЯ О БД:
│ Размер БД: 125 MB
│ Таблицы:
│  - news_items: 98 MB
│  - feeds: 2 MB
│  - publications: 25 MB
└

================================================================================
📊 ИТОГОВАЯ СВОДКА:
================================================================================
✅ RSS Лент подключено: 3
📥 Новостей обработано: 342
⏳ Ожидают публикации: 45
✔️  Опубликовано: 297
📊 Среднее качество: 72.5/100
================================================================================
```

## Автоматизация

Вы можете автоматизировать периодический запуск теста:

### Linux/Mac (Cron)

```bash
# Добавить в crontab: crontab -e
# Запускать каждый час
0 * * * * cd /path/to/ultrabot && python check_status.py >> logs/status.log 2>&1
```

### Windows (Task Scheduler)

```powershell
# Создать задачу в PowerShell (от администратора):
$action = New-ScheduledTaskAction -Execute 'python' -Argument 'C:\path\to\ultrabot\check_status.py'
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 1) -At (Get-Date) -Once
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "UlrabotStatusCheck" -Description "Check Ultrabot system status"
```

## Интеграция с мониторингом

Результаты теста можно интегрировать в системы мониторинга:

```python
# Пример использования в собственном коде
from tests.test_global_status import run_global_status_check
import asyncio

async def send_to_monitoring():
    # Запустить проверку
    await run_global_status_check()
    # Отправить результаты в систему мониторинга
    # send_metrics_to_prometheus(...)
```

## Требования

- PostgreSQL база данных должна быть запущена и доступна
- Переменные окружения в `.env` должны быть корректными
- Python 3.9+
- Установленные зависимости: `pip install -r requirements.txt`

## Troubleshooting

### Ошибка: "Error: Database connection failed"

Проверьте:
1. PostgreSQL запущен (`docker-compose up -d` или локальный сервер)
2. Переменные в `.env` файле верны
3. Сеть доступна (`ping localhost:5432`)

### Ошибка: "No feeds found"

Это нормально - добавьте RSS ленты через API или БД:

```bash
make db-migrate  # Убедиться что БД инициализирована
python add_gaming_feeds.py  # Добавить предустановленные ленты
```

### Медленное выполнение теста

Если БД большая, выполнение может занять время. Добавьте индексы:

```sql
CREATE INDEX IF NOT EXISTS idx_news_items_is_published ON news_items(is_published);
CREATE INDEX IF NOT EXISTS idx_news_items_score ON news_items(score DESC);
CREATE INDEX IF NOT EXISTS idx_news_items_created_at ON news_items(created_at DESC);
```

## Расширение теста

Чтобы добавить свои метрики, отредактируйте `tests/test_global_status.py`:

```python
# Добавить в раздел "АНАЛИТИКА"
# Ваша кастомная метрика
print("│ Ваша метрика: значение")
```
