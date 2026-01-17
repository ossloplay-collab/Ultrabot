# 🗄️ Database Initialization Scripts

## 📋 Описание

В этой папке находятся скрипты для инициализации базы данных Ultrabot.

### Создаваемые таблицы:

- **feeds** - Источники RSS лент
- **news_items** - Агрегированные новости
- **publications** - Опубликованные материалы в Telegram
- **metrics_logs** - Логирование метрик и событий
- **deduplication_cache** - Кэш для проверки дубликатов

### Создаваемые представления (Views):

- **published_news_summary** - Сводка опубликованных новостей
- **pending_publications** - Новости в очереди на публикацию
- **feed_statistics** - Статистика по источникам

---

## 🚀 Использование

### Windows (PowerShell)

```powershell
# Откройте PowerShell в папке проекта
cd C:\path\to\Ultrabot

# Запустите скрипт инициализации
.\init-db.ps1
```

**Требования:**
- Docker Desktop запущен
- PostgreSQL контейнер доступен

### Linux / macOS (Bash)

```bash
# Откройте терминал в папке проекта
cd /path/to/Ultrabot

# Запустите скрипт инициализации
./init-db.sh
```

**Требования:**
- Docker и docker-compose установлены
- PostgreSQL контейнер доступен

---

## 📝 Ручное выполнение SQL

Если скрипты не работают, можете выполнить SQL команды вручную:

### Вариант 1: Через docker-compose

```powershell
# Windows
docker-compose exec postgres psql -U ultrabot -d ultrabot -f docker/init.sql

# Linux/macOS
docker-compose exec postgres psql -U ultrabot -d ultrabot < docker/init.sql
```

### Вариант 2: Интерактивная сессия

```bash
# Подключиться к БД
docker-compose exec postgres psql -U ultrabot -d ultrabot

# Затем скопировать и вставить SQL команды из init.sql
```

---

## 🔍 Проверка результата

После инициализации проверьте, что таблицы созданы:

```bash
# Список таблиц
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "\dt"

# Список представлений (views)
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "\dv"

# Количество фидов
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) FROM feeds;"

# Количество новостей
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "SELECT COUNT(*) FROM news_items;"
```

---

## 📊 Полезные SQL запросы

### Статистика по источникам

```sql
SELECT * FROM feed_statistics;
```

### Опубликованные новости

```sql
SELECT * FROM published_news_summary ORDER BY published_at DESC LIMIT 20;
```

### Новости в очереди

```sql
SELECT * FROM pending_publications;
```

### Удалить все данные (осторожно!)

```sql
TRUNCATE publications CASCADE;
TRUNCATE news_items CASCADE;
TRUNCATE feeds CASCADE;
```

---

## 🛠️ Файлы скриптов

| Файл | ОС | Формат | Описание |
|------|-----|---------|----------|
| `init-db.ps1` | Windows | PowerShell | Интерактивный скрипт с проверками |
| `init-db.sh` | Linux/macOS | Bash | Скрипт с цветным выводом |
| `docker/init.sql` | Все | SQL | Чистый SQL для ручного выполнения |

---

## ⚙️ Что делают скрипты

1. ✅ Проверяют, запущен ли Docker
2. ✅ Проверяют, запущен ли PostgreSQL контейнер
3. ✅ Создают все необходимые таблицы
4. ✅ Создают индексы для оптимизации
5. ✅ Создают представления (views)
6. ✅ Проверяют результаты

---

## 🐛 Решение проблем

### Ошибка: "relation already exists"

**Решение:** Это нормально, таблица уже существует.

```bash
docker-compose exec postgres psql -U ultrabot -d ultrabot -c "DROP TABLE IF EXISTS news_items CASCADE;"
```

### Ошибка: "permission denied"

**Решение:** Проверьте права доступа к файлам скриптов:

```bash
# Linux/macOS
chmod +x init-db.sh

# Windows - запустите PowerShell от администратора
```

### Ошибка: "connection refused"

**Решение:** PostgreSQL контейнер не запущен:

```bash
docker-compose up -d postgres
docker-compose logs postgres
```

---

## 📞 Помощь

- Полная документация: [WINDOWS_SETUP_GUIDE_RU.md](../WINDOWS_SETUP_GUIDE_RU.md)
- Быстрый старт: [QUICK_START_WINDOWS.md](../QUICK_START_WINDOWS.md)
- Общая документация: [GETTING_STARTED.md](../GETTING_STARTED.md)
