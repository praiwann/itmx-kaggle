import os
import duckdb
from utils.spark_config import get_spark_session

DUCKDB_PATH = os.environ.get("DUCKDB_PATH", "data/itmx_kaggle.duckdb")
KAGGLE_DATA_PATH = os.environ.get("KAGGLE_DATA_PATH", "data/raw/kaggle")


def query_duckdb_with_spark():
    spark = get_spark_session("DuckDB_Query_Job")

    conn = duckdb.connect(DUCKDB_PATH, read_only=True)

    df = conn.execute("SELECT * FROM staging.eth_transaction limit 10").fetchdf()

    spark_df = spark.createDataFrame(df)

    spark_df.createOrReplaceTempView("metrics")

    result_df = spark.sql("""
        SELECT
            *
        FROM metrics
    """)

    result_df.show()

    conn.close()
    spark.stop()

    return "Spark processing completed"


if __name__ == "__main__":
    print("Running DuckDB queries with Spark...")
    query_duckdb_with_spark()
    print("All Spark operations completed!")
