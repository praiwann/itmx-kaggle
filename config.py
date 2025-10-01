"""
Configuration for data paths
Handles both local and container environments
"""
import os
from pathlib import Path

# Detect if running in container or local
IS_CONTAINER = os.environ.get("CONTAINER_ENV") == "true"

# Base paths
if IS_CONTAINER:
    # Container paths (volumes mounted in docker-compose.yml)
    DATA_DIR = Path("/data")
    PROJECT_DIR = Path("/app")
else:
    # Local paths
    DATA_DIR = Path(__file__).parent / "data"
    PROJECT_DIR = Path(__file__).parent

# Database paths
DUCKDB_PATH = str(DATA_DIR / "itmx_kaggle.duckdb")

# Data directories
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"
KAGGLE_DATA_DIR = RAW_DATA_DIR / "kaggle"

# Ensure directories exist
RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
KAGGLE_DATA_DIR.mkdir(parents=True, exist_ok=True)

print(f"Configuration loaded: {'Container' if IS_CONTAINER else 'Local'}")
print(f"DuckDB path: {DUCKDB_PATH}")
print(f"Data directory: {DATA_DIR}")