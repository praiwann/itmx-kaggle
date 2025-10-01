# Check if .env is a directory and fix it
$(shell if [ -d .env ]; then rm -rf .env && cp .env.example .env; fi)

# Load .env file if it exists and is a file
ifneq (,$(wildcard ./.env))
    ifeq (,$(shell [ -d .env ] && echo "dir"))
        include .env
        export
    endif
endif

.PHONY: install run-local run-docker clean test env-check

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
	PYTHONPATH=. poetry run python $(FILE)

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

# Deploy all flows
prefect-deploy: env-check
	PYTHONPATH=. poetry run python prefect_utils.py deploy-all

# List all flows and deployments
prefect-list:
	PYTHONPATH=. poetry run python prefect_utils.py list

# Run a specific flow (usage: make prefect-run FLOW=sample_etl_pipeline)
prefect-run:
	PYTHONPATH=. poetry run python prefect_utils.py run $(FLOW)

# Open Prefect UI
prefect-ui:
	@echo "Opening Prefect UI at $(PREFECT_API_URL)"
	@open $(PREFECT_API_URL) || xdg-open $(PREFECT_API_URL) || echo "Please open $(PREFECT_API_URL) in your browser"

# Start Prefect server locally
prefect-server:
	PREFECT_API_URL=$(PREFECT_API_URL) prefect server start

dbt-run:
	cd dbt && poetry run dbt run --project-dir . --profiles-dir . --target $(DBT_TARGET)

dbt-build:
	cd dbt && poetry run dbt build --project-dir . --profiles-dir . --target $(DBT_TARGET)

dbt-test:
	cd dbt && poetry run dbt test --project-dir . --profiles-dir . --target $(DBT_TARGET)

dbt-docs:
	cd dbt && poetry run dbt docs generate --project-dir . --profiles-dir . --target $(DBT_TARGET)
	cd dbt && poetry run dbt docs serve --project-dir . --profiles-dir .

clean:
	rm -rf dbt/target dbt/dbt_packages dbt/logs
	rm -f $(DUCKDB_PATH)*.wal $(DUCKDB_PATH)*.tmp
	rm -rf $(DATA_PROCESSED_PATH)/*
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	rm -rf $(LOG_PATH)/*

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
	@echo "Project initialized. Please place MulDiGraph.pkl in $(DATA_RAW_PATH)/kaggle/"

# Run the complete pipeline (without Prefect server)
pipeline: env-check
	@echo "Running complete pipeline..."
	@echo "Note: Running in local mode without Prefect server"
	PREFECT_API_URL="" PYTHONPATH=. poetry run python flows/kaggle_data_prep.py
	cd dbt && poetry run dbt build --project-dir . --profiles-dir . --target $(DBT_TARGET)
	@echo "Pipeline completed successfully!"

# Run pipeline with Prefect server
pipeline-prefect: env-check
	@echo "Running pipeline with Prefect server..."
	@echo "Make sure Prefect server is running (make prefect-server)"
	PYTHONPATH=. poetry run python flows/kaggle_data_prep.py
	cd dbt && poetry run dbt build --project-dir . --profiles-dir . --target $(DBT_TARGET)
	@echo "Pipeline completed successfully!"

help:
	@echo "ITMX Kaggle Pipeline - Available Commands"
	@echo "========================================="
	@echo "Setup:"
	@echo "  make init          - Initialize project (create .env, install deps, create dirs)"
	@echo "  make install       - Install dependencies"
	@echo "  make env-check     - Check/create .env file"
	@echo ""
	@echo "Pipeline:"
	@echo "  make pipeline        - Run complete ETL pipeline (local mode)"
	@echo "  make pipeline-prefect - Run pipeline with Prefect server"
	@echo "  make run FILE=x      - Run a specific Python file"
	@echo ""
	@echo "Prefect:"
	@echo "  make prefect-server  - Start Prefect server"
	@echo "  make prefect-deploy  - Deploy all flows"
	@echo "  make prefect-list    - List flows and deployments"
	@echo "  make prefect-run FLOW=x - Run specific flow"
	@echo "  make prefect-ui      - Open Prefect UI"
	@echo ""
	@echo "dbt:"
	@echo "  make dbt-run       - Run dbt models"
	@echo "  make dbt-build     - Build and test models"
	@echo "  make dbt-test      - Run dbt tests"
	@echo "  make dbt-docs      - Generate and serve dbt docs"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up     - Start all services"
	@echo "  make docker-down   - Stop all services"
	@echo "  make docker-logs   - View container logs"
	@echo "  make docker-status - Check service status"
	@echo ""
	@echo "Utils:"
	@echo "  make clean         - Clean generated files"
	@echo "  make test          - Run tests"
	@echo "  make show-env      - Display environment config"
	@echo "  make help          - Show this help message"