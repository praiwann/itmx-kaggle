# ITMX Kaggle - Ethereum Phishing Detection Pipeline

A modern data pipeline for analyzing Ethereum transaction networks to detect phishing accounts, built with Prefect, dbt, DuckDB, and PySpark.

## 📌 Important Notes

**Project Context:**
- This project was created for researching efficient ETL pipeline development on local infrastructure (cloud solutions are not the primary focus)
- The data model design is based on specific requirements from ITMX, a developer and service provider of Thailand's electronic payment infrastructure
- **⚡ The answer to ITMX's questions can be found in the `gold_transaction_summary` model**
- The project can be further enhanced to consolidate all pipeline runs under Prefect control flow (currently dbt runs independently, but the infrastructure is already in place)

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
  - `gold_transaction_summary`: Aggregated transaction metrics (contains ITMX business answers)
  - `gold_hourly_network_metrics`: Time-series network analysis

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.11+ with Poetry (for local development only)
- Kaggle dataset: MulDiGraph.pkl

### Setup Instructions

1. **Clone the repository**
```bash
git clone <repository-url>
cd itmx-kaggle
```

2. **Initialize the project**
```bash
make init
```
This will:
- Create .env from .env.example
- Install local dependencies (for development)
- Create necessary directories
- Set up Python path configuration

3. **Place your data**
   - Download the Kaggle dataset (MulDiGraph.pkl)
   - Place it in `data/raw/kaggle/MulDiGraph.pkl`

4. **Build Docker images**
```bash
make docker-build
```

### Running the Pipeline

All pipeline operations run in Docker for consistency and ease of use.

#### Step 1: Start Docker Services
```bash
make docker-up
```
This starts:
- **Prefect server** (orchestration) - UI at http://localhost:4200
- **Spark cluster** (processing) - UI at http://localhost:8081
- **DuckDB server** (database)

#### Step 2: Deploy Flows (first time only)
```bash
make prefect-deploy
```

#### Step 3: Run the Pipeline

**Option A: Run ETL Pipeline**
```bash
# Run default pipeline
make pipeline

# Or run specific flow
make pipeline FLOW=kaggle_etl_pipeline
```

**Option B: Run dbt Transformations**
```bash
# Run all dbt models and tests
make dbt

# Run only dbt models (without tests)
make dbt-run

# Run only dbt tests
make dbt-test
```

#### Step 4: Monitor Progress
```bash
# Open Prefect UI to monitor flows
make prefect-ui

# View Docker logs
make docker-logs

# Check service status
make docker-status
```

#### Step 5: Stop Services (when done)
```bash
make docker-down
```

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

### Quick Command Reference

```bash
# Setup (run once)
make init               # Initialize project
make docker-build       # Build Docker images

# Docker Services
make docker-up          # Start all services
make docker-down        # Stop all services
make docker-status      # Check service status
make docker-logs        # View container logs

# Pipeline Execution (in Docker)
make pipeline           # Run default ETL pipeline
make pipeline FLOW=x    # Run specific flow
make dbt                # Run dbt transformations

# Additional Operations
make prefect-deploy     # Deploy flows to Prefect
make prefect-list       # List deployed flows
make prefect-ui         # Open Prefect UI
make dbt-run            # Run dbt models only
make dbt-test           # Run dbt tests only
make dbt-docs           # Generate and serve dbt docs

# Utilities
make clean              # Clean generated files
make show-env           # Display environment config
make help               # Show all available commands
```

### Complete Workflow Example

```bash
# One-time setup
make init               # Initialize project
make docker-build       # Build images

# Daily workflow
make docker-up          # Start services
make prefect-deploy     # Deploy flows (if needed)
make pipeline           # Run ETL pipeline
make dbt                # Run transformations
make docker-down        # Stop services when done
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

The project runs three containerized services:

1. **Prefect**: Workflow orchestration and pipeline execution
   - UI: http://localhost:4200
   - Includes dbt and all Python dependencies
   - Manages flow deployments and execution

2. **Spark**: Distributed processing for large-scale data
   - UI: http://localhost:8081
   - Master: spark://localhost:7077
   - Used for heavy data processing tasks

3. **DuckDB**: Lightweight analytical database
   - File server: http://localhost:8080
   - Database location: data/itmx_kaggle.duckdb
   - Stores all pipeline data

## Monitoring

- **Prefect UI**: http://localhost:4200 - Monitor flow runs and deployments
- **Spark UI**: http://localhost:8081 - Track Spark job execution

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Dataset source: Kaggle Ethereum Phishing Transaction Network
- Built with: Prefect, dbt, DuckDB, PySpark
- Medallion architecture inspired by Databricks best practices

---

**Note**: Ensure all data files are properly placed in the `data/raw/kaggle/` directory before running the pipeline. The main dataset file `MulDiGraph.pkl` is required for the ETL process to work correctly.