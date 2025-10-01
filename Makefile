.PHONY: install run-local run-docker clean test

install:
	poetry install

# Generic run command: make run FILE=flows/sample_pipeline.py
run:
	poetry run python $(FILE)

docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-status:
	docker-compose ps

# Deploy all flows
prefect-deploy:
	poetry run python prefect_utils.py deploy-all

# List all flows and deployments
prefect-list:
	poetry run python prefect_utils.py list

# Run a specific flow (usage: make prefect-run FLOW=sample_etl_pipeline)
prefect-run:
	poetry run python prefect_utils.py run $(FLOW)

# Open Prefect UI
prefect-ui:
	@echo "Opening Prefect UI at http://localhost:4200"
	@open http://localhost:4200 || xdg-open http://localhost:4200 || echo "Please open http://localhost:4200 in your browser"

dbt-run:
	cd dbt && poetry run dbt run --profiles-dir .

dbt-build:
	cd dbt && poetry run dbt build --profiles-dir .

dbt-test:
	cd dbt && poetry run dbt test --profiles-dir .

clean:
	rm -rf dbt/target dbt/dbt_packages dbt/logs
	rm -f data/*.duckdb*
	rm -rf data/processed/*
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

test:
	poetry run pytest tests/