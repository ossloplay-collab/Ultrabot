# 🌍 ГЛОБАЛЬНЫЙ ТЕСТ СИСТЕМЫ - КРАТКАЯ СПРАВКА

## Что было создано:

### 1. 📄 Тестовый файл
- **Файл**: `tests/test_global_status.py`
- **Что делает**: Подключается к БД и выводит полную статистику
- **Показывает**:
  - ✅ Все подключенные RSS ленты (статус, приоритет, ошибки)
  - 📊 Статистику новостей (всего, опубликовано, ожидают)
  - ⭐ Top 5 новостей по рейтингу
  - 📈 Средний, макс и мин рейтинг
  - 🗄️ Информацию о БД (размер, таблицы)
  - 📡 Распределение новостей по источникам

### 2. 🐍 Python скрипты для запуска
- **`check_status.py`** - основной скрипт (работает везде)
- **`check_status.sh`** - для Linux/Mac
- **`check_status.ps1`** - для Windows PowerShell

### 3. 📖 Документация
- **`GLOBAL_TEST.md`** - полная документация с примерами

### 4. 🔨 Новые команды Make
- `make status` - быстрая проверка статуса
- `make test-global` - подробный тест с pytest

---

## 🚀 БЫСТРЫЙ ЗАПУСК

### Вариант 1: Самый простой (Linux/Mac/Windows)
```bash
make status
```

### Вариант 2: Через pytest с полным выводом
```bash
make test-global
```

### Вариант 3: Напрямую Python
```bash
python check_status.py
```

### Вариант 4: PowerShell на Windows
```powershell
.\check_status.ps1
```

### Вариант 5: Linux/Mac shell
```bash
chmod +x check_status.sh
./check_status.sh
```

---

## ✨ ЧТО ПОКАЗЫВАЕТ ТЕСТ

При запуске вы увидите красивый вывод:

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
...

┌─ ОЖИДАЮТ ПУБЛИКАЦИЮ:
│ Новостей ожидают публикации: 45
│ Top 5 по рейтингу:
│  1. [92 ⭐] New Counter-Strike 2 Tournament...
...

┌─ АНАЛИТИКА:
│ Средний рейтинг: 72.5 ⭐
│ Макс рейтинг: 98 ⭐
│ Мин рейтинг: 15 ⭐
│ Процент опубликованных: 86.8%
...

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

---

## 📋 ТРЕБОВАНИЯ

Перед запуском убедитесь:

1. **PostgreSQL работает**:
   ```bash
   docker-compose up -d
   # или локальный сервер PostgreSQL запущен
   ```

2. **`.env` файл настроен**:
   ```bash
   cat .env | grep DATABASE_URL
   ```

3. **БД инициализирована**:
   ```bash
   make db-migrate
   # или python -m alembic upgrade head
   ```

4. **Python 3.9+**:
   ```bash
   python --version
   ```

---

## 🔧 РАСШИРЕНИЕ ТЕСТА

Хотите добавить свои метрики? Отредактируйте `tests/test_global_status.py`:

```python
# В разделе "АНАЛИТИКА" добавьте:
print("│ Моя метрика: значение")
```

---

## 🆘 РЕШЕНИЕ ПРОБЛЕМ

### "Error: Database connection failed"
```bash
# Проверить БД запущена
docker-compose ps

# Проверить подключение
psql -h localhost -U ultrabot -d ultrabot -c "SELECT 1"
```

### "No feeds found"
```bash
# Это нормально - добавьте ленты:
python add_gaming_feeds.py
# или через API
```

### "ошибка с импортами"
```bash
# Убедитесь что вы в корне проекта
cd /path/to/Ultrabot
python check_status.py
```

---

## 📊 ИНТЕГРАЦИЯ С МОНИТОРИНГОМ

Вы можете использовать результаты в своей системе мониторинга:

```python
import asyncio
from tests.test_global_status import run_global_status_check

async def monitor():
    await run_global_status_check()
    # Отправить метрики в Prometheus, DataDog и т.д.
```

---

## 📅 АВТОМАТИЗАЦИЯ

Запускайте тест автоматически через cron (Linux) или Task Scheduler (Windows):

**Linux (crontab -e)**:
```cron
0 * * * * cd /path/to/ultrabot && python check_status.py >> logs/status.log 2>&1
```

**Windows (PowerShell Admin)**:
```powershell
$action = New-ScheduledTaskAction -Execute 'python' -Argument 'C:\path\to\ultrabot\check_status.py'
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 1) -Once -At (Get-Date)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "UlbotStatus"
```

---

## 🎯 СЛЕДУЮЩИЕ ШАГИ

1. ✅ Запустить тест: `make status`
2. 📊 Проверить статистику в выводе
3. 🔧 При нужде отредактировать `GLOBAL_TEST.md`
4. 📈 Добавить в систему мониторинга

**Готово!** 🎉
