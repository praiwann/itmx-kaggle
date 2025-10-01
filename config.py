"""
Centralized configuration module for loading environment variables
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file
load_dotenv()

# Get the project root directory (where this config.py file is located)
PROJECT_ROOT = Path(__file__).parent.absolute()

# Database Configuration - make paths absolute
DUCKDB_PATH = os.getenv("DUCKDB_PATH", "data/itmx_kaggle.duckdb")
if not os.path.isabs(DUCKDB_PATH):
    DUCKDB_PATH = str(PROJECT_ROOT / DUCKDB_PATH)
DUCKDB_DATABASE = os.getenv("DUCKDB_DATABASE", "itmx_kaggle")

# Data Paths - make paths absolute
DATA_RAW_PATH = os.getenv("DATA_RAW_PATH", "data/raw")
if not os.path.isabs(DATA_RAW_PATH):
    DATA_RAW_PATH = str(PROJECT_ROOT / DATA_RAW_PATH)

DATA_PROCESSED_PATH = os.getenv("DATA_PROCESSED_PATH", "data/processed")
if not os.path.isabs(DATA_PROCESSED_PATH):
    DATA_PROCESSED_PATH = str(PROJECT_ROOT / DATA_PROCESSED_PATH)

KAGGLE_DATA_PATH = os.getenv("KAGGLE_DATA_PATH", f"{DATA_RAW_PATH}/kaggle")
if not os.path.isabs(KAGGLE_DATA_PATH):
    KAGGLE_DATA_PATH = str(PROJECT_ROOT / "data" / "raw" / "kaggle")

# Prefect Configuration
PREFECT_API_URL = os.getenv("PREFECT_API_URL", "http://localhost:4200/api")
PREFECT_SERVER_HOST = os.getenv("PREFECT_SERVER_HOST", "0.0.0.0")
PREFECT_SERVER_PORT = int(os.getenv("PREFECT_SERVER_PORT", "4200"))

# Spark Configuration
SPARK_MASTER = os.getenv("SPARK_MASTER", "spark://localhost:7077")
SPARK_LOCAL = os.getenv("SPARK_LOCAL", "false").lower() == "true"
SPARK_APP_NAME = os.getenv("SPARK_APP_NAME", "ITMX_Kaggle_Pipeline")
SPARK_EXECUTOR_MEMORY = os.getenv("SPARK_EXECUTOR_MEMORY", "2g")
SPARK_EXECUTOR_CORES = int(os.getenv("SPARK_EXECUTOR_CORES", "2"))

# DBT Configuration
DBT_PROFILES_DIR = os.getenv("DBT_PROFILES_DIR", "dbt")
DBT_PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", "dbt")
DBT_TARGET = os.getenv("DBT_TARGET", "dev")
DBT_THREADS = int(os.getenv("DBT_THREADS", "4"))

# Docker Configuration
DOCKER_NETWORK = os.getenv("DOCKER_NETWORK", "pipeline-network")
DOCKER_DATA_VOLUME = os.getenv("DOCKER_DATA_VOLUME", "./data:/data")

# Logging Configuration
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
LOG_PATH = os.getenv("LOG_PATH", "logs")
if not os.path.isabs(LOG_PATH):
    LOG_PATH = str(PROJECT_ROOT / LOG_PATH)

# Create necessary directories (using absolute paths)
Path(DATA_RAW_PATH).mkdir(parents=True, exist_ok=True)
Path(DATA_PROCESSED_PATH).mkdir(parents=True, exist_ok=True)
Path(KAGGLE_DATA_PATH).mkdir(parents=True, exist_ok=True)
Path(LOG_PATH).mkdir(parents=True, exist_ok=True)

# Validate critical paths
if not Path(f"{KAGGLE_DATA_PATH}/MulDiGraph.pkl").exists():
    print(f"Warning: MulDiGraph.pkl not found in {KAGGLE_DATA_PATH}")
