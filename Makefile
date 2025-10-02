# Check if .env is a directory and fix it
$(shell if [ -d .env ]; then rm -rf .env && cp .env.example .env; fi)

# Load .env file if it exists and is a file
ifneq (,$(wildcard ./.env))
    ifeq (,$(shell [ -d .env ] && echo "dir"))
        include .env
        export
    endif
endif

.PHONY: install run-local run-docker clean test env-check init pipeline dbt dbt-run dbt-test dbt-docs docker-build docker-up docker-down docker-logs docker-status prefect-deploy prefect-list prefect-ui show-env help

# Check if .env exists, create from example if not
env-check:
	@if [ -d .env ]; then \
		echo "ERROR: .env is a directory, removing it..."; \
		rm -rf .env; \
	fi
	@if [ ! -f .env ]; then \
		echo "Creating .env from .env.example..."; \
		cp .env.example .env; \
		echo "Please review and update .env with your settings"; \
	fi

install: env-check
	poetry install

# Generic run command: make run FILE=flows/sample_pipeline.py
run:
	poetry run python $(FILE)

docker-build:
	docker-compose build

docker-up: env-check
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-status:
	docker-compose ps

# Deploy flows in Docker
prefect-deploy:
	docker-compose exec prefect python prefect_utils.py deploy-all

# List flows in Docker
prefect-list:
	docker-compose exec prefect python prefect_utils.py list

# Open Prefect UI
prefect-ui:
	@echo "Opening Prefect UI at http://localhost:4200"
	@open http://localhost:4200 || xdg-open http://localhost:4200 || echo "Please open http://localhost:4200 in your browser"

# dbt operations in Docker
dbt-run:
	docker-compose exec prefect dbt run --project-dir dbt --profiles-dir dbt --target docker

dbt-test:
	docker-compose exec prefect dbt test --project-dir dbt --profiles-dir dbt --target docker

dbt-docs:
	docker-compose exec prefect dbt docs generate --project-dir dbt --profiles-dir dbt --target docker
	docker-compose exec prefect dbt docs serve --project-dir dbt --profiles-dir dbt

clean:
	rm -rf dbt/target dbt/dbt_packages dbt/logs
	rm -f $(DUCKDB_PATH)*.wal $(DUCKDB_PATH)*.tmp
	rm -rf $(DATA_PROCESSED_PATH)/*
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	rm -rf $(LOG_PATH)/*
	# Clean up any accidentally created directories in subdirs
	rm -rf flows/data flows/logs 2>/dev/null || true

test:
	poetry run pytest tests/ -v

# Show current environment configuration
show-env:
	@echo "=== Current Environment Configuration ==="
	@echo "ENVIRONMENT: $(ENVIRONMENT)"
	@echo "DUCKDB_PATH: $(DUCKDB_PATH)"
	@echo "DATA_RAW_PATH: $(DATA_RAW_PATH)"
	@echo "DATA_PROCESSED_PATH: $(DATA_PROCESSED_PATH)"
	@echo "PREFECT_API_URL: $(PREFECT_API_URL)"
	@echo "SPARK_MASTER: $(SPARK_MASTER)"
	@echo "DBT_TARGET: $(DBT_TARGET)"
	@echo "LOG_LEVEL: $(LOG_LEVEL)"

# Initialize project structure
init: env-check install
	@echo "Initializing project structure..."
	@mkdir -p $(DATA_RAW_PATH)/kaggle
	@mkdir -p $(DATA_PROCESSED_PATH)
	@mkdir -p $(LOG_PATH)
	@echo "Setting up Python path..."
	@poetry run python scripts/setup_python_path.py
	@echo "Project initialized. Please place MulDiGraph.pkl in $(DATA_RAW_PATH)/kaggle/"

# Run pipeline in Docker (usage: make pipeline or make pipeline FLOW=kaggle_data_prep)
pipeline:
	@echo "Running pipeline in Docker..."
	@if [ -z "$(FLOW)" ]; then \
		docker-compose exec prefect python prefect_utils.py run kaggle_data_prep; \
	else \
		docker-compose exec prefect python prefect_utils.py run $(FLOW); \
	fi

# Run dbt in Docker (use THREADS=1 for compatibility, THREADS=4 for speed if supported)
dbt:
	docker-compose exec prefect dbt build --project-dir dbt --profiles-dir dbt --target docker --threads $(or $(THREADS),1)

help:
	@echo "ITMX Kaggle Pipeline - Available Commands"
	@echo "========================================="
	@echo ""
	@echo "1. Setup (run once):"
	@echo "   make init          - Initialize project (create .env, install deps, create dirs)"
	@echo "   make docker-build  - Build Docker images"
	@echo ""
	@echo "2. Start Docker:"
	@echo "   make docker-up     - Start all services (Prefect, Spark, DuckDB)"
	@echo ""
	@echo "3. Run Pipeline (in Docker):"
	@echo "   make pipeline      - Run default ETL pipeline"
	@echo "   make pipeline FLOW=<name> - Run specific flow"
	@echo "   make dbt           - Run dbt transformations"
	@echo ""
	@echo "Additional Commands:"
	@echo "  Docker:"
	@echo "   make docker-down   - Stop all services"
	@echo "   make docker-logs   - View container logs"
	@echo "   make docker-status - Check service status"
	@echo ""
	@echo "  Prefect:"
	@echo "   make prefect-deploy - Deploy flows to Prefect"
	@echo "   make prefect-list   - List deployed flows"
	@echo "   make prefect-ui     - Open Prefect UI (http://localhost:4200)"
	@echo ""
	@echo "  dbt:"
	@echo "   make dbt-run       - Run dbt models only"
	@echo "   make dbt-test      - Run dbt tests only"
	@echo "   make dbt-docs      - Generate and serve dbt docs"
	@echo ""
	@echo "  Utilities:"
	@echo "   make clean         - Clean generated files"
	@echo "   make show-env      - Display environment config"
	@echo "   make help          - Show this help message"