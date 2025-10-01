"""
Centralized Spark configuration for connecting to cluster or local
"""
import os
from pyspark.sql import SparkSession
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def get_spark_session(app_name="DuckDB_Integration"):
    """
    Get Spark session based on environment

    The Spark master endpoint (port 7077) is exposed in docker-compose.yml:
    - From localhost: spark://localhost:7077
    - From Docker containers: spark://spark-master:7077
    """

    spark_master = os.environ.get("SPARK_MASTER")
    force_local = os.environ.get("SPARK_LOCAL", "").lower() == "true"

    builder = SparkSession.builder.appName(app_name)

    if spark_master and not force_local:
        # Connect to Spark cluster
        print(f"Connecting to Spark cluster at {spark_master}")
        builder = builder.master(spark_master) \
            .config("spark.executor.memory", "1g") \
            .config("spark.executor.cores", "2")
    else:
        # Local mode
        print("Running in local mode")
        builder = builder.master("local[*]") \
            .config("spark.driver.memory", "2g")

    # Common configurations
    spark = builder \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .getOrCreate()

    return spark

# Usage:
# From localhost to Docker cluster:
#   export SPARK_MASTER=spark://localhost:7077
#   python spark/your_script.py
#
# From inside Docker:
#   export SPARK_MASTER=spark://spark-master:7077
#   python /app/spark/your_script.py