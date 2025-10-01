# ITMX Kaggle - Ethereum Phishing Detection Pipeline

A modern data pipeline for analyzing Ethereum transaction networks to detect phishing accounts, built with Prefect, dbt, DuckDB, and PySpark.

## Overview

This project implements an end-to-end data pipeline for processing and analyzing Ethereum transaction data from a Kaggle competition dataset. It uses a medallion architecture (Bronze -> Silver -> Gold) to transform raw network graph data into analytical insights about phishing patterns in Ethereum transactions.

### Key Features

- **Orchestration**: Prefect for workflow management and scheduling
- **Data Transformation**: dbt with DuckDB for ELT processing
- **Storage**: DuckDB as a lightweight analytical database
- **Processing**: PySpark integration for large-scale data processing
- **Architecture**: Medallion architecture (Bronze/Silver/Gold layers)
- **Containerization**: Docker support for easy deployment

## Architecture

```
+-------------------+
|   Raw Data        |
| (MulDiGraph.pkl)  |
+--------+----------+
         |
         v
    +---------+
    | Prefect | (Orchestration)
    +----+----+
         |
         v
    +---------+
    | Staging | (DuckDB)
    +----+----+
         |
         v
    +---------+
    |   dbt   | (Transformation)
    +----+----+
         |
         v
    +---------------------+
    | Bronze -> Silver    |
    |     -> Gold         |
    +---------------------+
```

### Data Layers

- **Staging**: Raw data loaded from NetworkX graph pickle file
  - `mst_eth_account`: Ethereum accounts with phishing labels
  - `eth_transaction`: Transaction records with amounts and timestamps

- **Bronze**: Raw data with minimal transformations
  - `bronze_raw_eth_account`: Account master data
  - `bronze_raw_transactions`: Transaction records

- **Silver**: Cleaned and enriched data
  - `silver_account_masters`: Processed account information
  - `silver_transactions`: Normalized transactions
  - `silver_transaction_enriched`: Transactions with account metadata

- **Gold**: Business-ready analytical models
  - `gold_transaction_summary`: Aggregated transaction metrics
  - `gold_hourly_network_metrics`: Time-series network analysis

## Quick Start

### Prerequisites

- Python 3.11+
- Poetry (for dependency management)
- Docker & Docker Compose (optional, for containerized deployment)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd itmx-kaggle
```

2. **Initialize the project** (recommended - handles everything automatically)
```bash
make init
```
This command will:
- Create .env from .env.example
- Install all dependencies
- Set up Python path configuration (no PYTHONPATH needed)
- Create necessary directories

Alternatively, you can set up manually:

```bash
# Create environment file
cp .env.example .env
# Edit .env with your configuration

# Install dependencies
poetry install

# Set up Python path (enables imports from project root)
poetry run python scripts/setup_python_path.py
```

3. **Place your data**
   - Download the Kaggle dataset (MulDiGraph.pkl)
   - Place it in `data/raw/kaggle/MulDiGraph.pkl`

### Running the Pipeline

#### Local Execution

1. **Start Prefect server** (in a separate terminal)
```bash
prefect server start
```

2. **Deploy flows to Prefect**
```bash
make prefect-deploy
```

3. **Run the ETL pipeline**
```bash
make prefect-run FLOW=kaggle_etl_pipeline
# or directly
poetry run python flows/kaggle_data_prep.py
```

4. **Run dbt transformations**
```bash
make dbt-build
```

5. **View results in Prefect UI**
```bash
make prefect-ui
# Opens http://localhost:4200
```

#### Docker Execution

1. **Build Docker images** (required first time or after Dockerfile changes)
```bash
make docker-build
```

2. **Start all services**
```bash
make docker-up
```

3. **Check service status**
```bash
make docker-status
```

4. **View logs**
```bash
make docker-logs
```

5. **Stop services**
```bash
make docker-down
```

**Note**: The Docker setup includes custom images with all dependencies pre-installed for both Prefect and Spark services.

## Project Structure

```
itmx-kaggle/
├── flows/                  # Prefect workflows
│   └── kaggle_data_prep.py # Main ETL pipeline
├── dbt/                    # dbt project
│   ├── models/
│   │   ├── bronze/        # Raw data models
│   │   ├── silver/        # Cleaned data models
│   │   └── gold/          # Analytical models
│   ├── dbt_project.yml   # dbt configuration
│   └── profiles.yml      # Database connections
├── data/
│   ├── raw/              # Source data
│   │   └── kaggle/       # Kaggle dataset
│   └── processed/        # Output data
├── .docker/              # Docker configurations
├── spark/                # PySpark scripts
├── prefect_utils.py      # Prefect management utilities
├── docker-compose.yml    # Container orchestration
├── Makefile             # Command shortcuts
├── pyproject.toml       # Python dependencies
└── README.md           # This file
```

## Available Commands

### Makefile Commands

```bash
# Installation & Setup
make install              # Install dependencies

# Prefect Operations
make prefect-deploy      # Deploy all flows
make prefect-list        # List flows and deployments
make prefect-run FLOW=x  # Run specific flow
make prefect-ui          # Open Prefect UI

# dbt Operations
make dbt-run            # Run dbt models
make dbt-build          # Build and test models
make dbt-test           # Run dbt tests

# Docker Operations
make docker-build       # Build containers
make docker-up          # Start services
make docker-down        # Stop services
make docker-logs        # View logs
make docker-status      # Check status

# Maintenance
make clean              # Clean generated files
make test               # Run tests
```

### Prefect Utilities

```bash
# Deploy all flows
python prefect_utils.py deploy-all

# List flows and deployments
python prefect_utils.py list

# Run a specific flow
python prefect_utils.py run <flow_name>
```

## Configuration

### Environment Variables

The project uses a centralized configuration system through `.env` files. Copy `.env.example` to `.env` and configure:

```bash
# Quick setup
make init  # Creates .env from .env.example and initializes project
```

#### Key Configuration Categories:

**Database Configuration**
```bash
DUCKDB_PATH=data/itmx_kaggle.duckdb      # DuckDB database file location
DUCKDB_DATABASE=itmx_kaggle              # Database name
```

**Data Paths**
```bash
DATA_RAW_PATH=data/raw                   # Raw data directory
DATA_PROCESSED_PATH=data/processed       # Processed data directory
KAGGLE_DATA_PATH=data/raw/kaggle        # Kaggle dataset location
```

**Prefect Configuration**
```bash
PREFECT_API_URL=http://localhost:4200/api  # Prefect API endpoint
PREFECT_SERVER_HOST=0.0.0.0               # Server bind address
PREFECT_SERVER_PORT=4200                  # Server port
```

**Spark Configuration**
```bash
SPARK_MASTER=spark://localhost:7077      # Spark cluster URL
SPARK_LOCAL=false                        # Set to true for local mode
SPARK_EXECUTOR_MEMORY=2g                 # Executor memory allocation
SPARK_EXECUTOR_CORES=2                   # CPU cores per executor
```

**DBT Configuration**
```bash
DBT_TARGET=dev                           # Target environment (dev/prod/docker)
DBT_THREADS=4                            # Parallel execution threads
DBT_PROFILES_DIR=dbt                    # Profiles directory
```

**Docker Configuration**
```bash
DOCKER_NETWORK=pipeline-network          # Docker network name
DOCKER_DATA_VOLUME=./data:/data         # Data volume mapping
```

**Additional Settings**
```bash
LOG_LEVEL=INFO                          # Logging verbosity
LOG_PATH=logs                           # Log file directory
ENVIRONMENT=development                 # Environment mode
```

### Configuration Management

The project includes several utilities for managing configuration:

```bash
# Show current configuration
make show-env

# Initialize project with .env
make init

# Check/create .env file
make env-check
```

### Using Configuration in Code

The project provides a centralized `config.py` module that automatically loads all environment variables:

```python
from config import DUCKDB_PATH, KAGGLE_DATA_PATH, PREFECT_API_URL
```

### dbt Profile

The dbt profile dynamically uses environment variables:
- Target environments: `dev`, `prod`, `docker`
- Configured via `DBT_TARGET` environment variable
- Thread count controlled by `DBT_THREADS`

## Data Model

### Source Data
- **MulDiGraph.pkl**: NetworkX MultiDiGraph containing:
  - Nodes: Ethereum accounts with phishing labels
  - Edges: Transactions with amounts and timestamps

### Key Metrics Generated
- Transaction volumes by account
- Network activity patterns
- Phishing account detection signals
- Hourly network metrics
- Account risk scores

## Testing

Run tests with:
```bash
make test
```

## Docker Services

The project includes three main services:

1. **DuckDB**: File server for database access (port 8080)
2. **Spark**: Apache Spark cluster (UI on port 8081, master on 7077)
3. **Prefect**: Workflow orchestration (UI on port 4200)

## Monitoring

- **Prefect UI**: http://localhost:4200 - Monitor flow runs and deployments
- **Spark UI**: http://localhost:8081 - Track Spark job execution

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Dataset source: Kaggle Ethereum Fraud Detection Competition
- Built with: Prefect, dbt, DuckDB, PySpark
- Medallion architecture inspired by Databricks best practices

---

**Note**: Ensure all data files are properly placed in the `data/raw/kaggle/` directory before running the pipeline. The main dataset file `MulDiGraph.pkl` is required for the ETL process to work correctly.