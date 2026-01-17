.PHONY: help install install-dev run run-dev test test-coverage lint format check clean docker-build docker-run db-migrate db-rollback

PYTHON := python3
VENV := venv
PYTHON_VENV := $(VENV)/bin/python
PIP_VENV := $(VENV)/bin/pip

help: ## Show this help message
	@echo "Ultrabot - Gaming News Aggregator"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	$(PYTHON) -m pip install --upgrade pip setuptools wheel
	$(PYTHON) -m pip install -r requirements.txt

install-dev: install ## Install with development dependencies
	$(PYTHON) -m pip install -e ".[dev]"

venv: ## Create virtual environment
	$(PYTHON) -m venv $(VENV)
	$(PIP_VENV) install --upgrade pip setuptools wheel
	$(PIP_VENV) install -r requirements.txt
	@echo ""
	@echo "Virtual environment created! Activate it with:"
	@echo "  source $(VENV)/bin/activate  # Linux/Mac"
	@echo "  $(VENV)\\Scripts\\activate    # Windows"

venv-dev: venv ## Create virtual environment with dev dependencies
	$(PIP_VENV) install -e ".[dev]"

run: ## Run application (requires .env file)
	$(PYTHON) -m src.main

run-dev: ## Run application in development mode with auto-reload
	$(PYTHON) -m uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

test: ## Run tests
	$(PYTHON) -m pytest tests/ -v

test-coverage: ## Run tests with coverage report
	$(PYTHON) -m pytest tests/ -v --cov=src --cov-report=html --cov-report=term

test-unit: ## Run unit tests only
	$(PYTHON) -m pytest tests/unit/ -v

test-integration: ## Run integration tests
	$(PYTHON) -m pytest tests/integration/ -v

test-e2e: ## Run E2E tests
	$(PYTHON) -m pytest tests/e2e/ -v

test-global: ## Run global status test (shows feeds, news stats, DB info)
	$(PYTHON) -m pytest tests/test_global_status.py -v -s

status: ## Check system status (RSS feeds, news, database)
	$(PYTHON) check_status.py

lint: ## Run all linters
	@echo "Running black..."
	$(PYTHON) -m black --check .
	@echo "Running isort..."
	$(PYTHON) -m isort --check-only .
	@echo "Running flake8..."
	$(PYTHON) -m flake8 src tests
	@echo "Running mypy..."
	$(PYTHON) -m mypy src --strict
	@echo "Running ruff..."
	$(PYTHON) -m ruff check .
	@echo "✅ All linters passed!"

format: ## Format code
	$(PYTHON) -m black .
	$(PYTHON) -m isort .
	$(PYTHON) -m ruff check . --fix

check: lint test ## Run all checks (lint + test)

type-check: ## Run mypy type checker
	$(PYTHON) -m mypy src --strict

clean: ## Clean up generated files
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	find . -type d -name .mypy_cache -exec rm -rf {} +
	find . -type d -name htmlcov -exec rm -rf {} +
	rm -f .coverage
	rm -rf build/ dist/

docker-build: ## Build Docker image
	docker build -f docker/Dockerfile -t ultrabot:latest .

docker-run: ## Run with Docker Compose
	docker-compose up -d

docker-stop: ## Stop Docker containers
	docker-compose down

docker-logs: ## Show Docker logs
	docker-compose logs -f

docker-clean: docker-stop ## Clean Docker resources
	docker-compose down -v
	docker rmi ultrabot:latest

db-migrate: ## Run database migrations
	$(PYTHON) -m alembic upgrade head

db-rollback: ## Rollback last migration
	$(PYTHON) -m alembic downgrade -1

db-new: ## Create new migration
	@read -p "Migration name: " name; \
	$(PYTHON) -m alembic revision --autogenerate -m "$$name"

.env: ## Create .env file from example
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file from .env.example"; \
		echo "⚠️  Please update .env with your credentials!"; \
	else \
		echo "⚠️  .env already exists"; \
	fi

setup: .env install ## Initial setup (install + create .env)
	@echo "✅ Setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Update .env file with your credentials"
	@echo "  2. Run: make docker-run"
	@echo "  3. Run: make db-migrate"
	@echo "  4. Run: make run"

setup-dev: .env venv-dev ## Development setup (venv + install + create .env)
	@echo "✅ Development setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Activate venv: source venv/bin/activate"
	@echo "  2. Update .env file with your credentials"
	@echo "  3. Run: make docker-run"
	@echo "  4. Run: make db-migrate"
	@echo "  5. Run: make run-dev"
