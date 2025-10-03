#!/bin/bash
# Submit Spark job to Docker cluster using mounted volume
# Usage: ./spark-submit.sh [script.py] [--quiet]

# Parse arguments
SCRIPT=""
QUIET=false

for arg in "$@"; do
    case $arg in
        --quiet)
            QUIET=true
            shift
            ;;
        *)
            if [ -z "$SCRIPT" ]; then
                SCRIPT="$arg"
            fi
            ;;
    esac
done

# Default script if none provided
SCRIPT=${SCRIPT:-duckdb_spark_query.py}

# Remove 'spark/' prefix if user included it
SCRIPT=${SCRIPT#spark/}

# Check if script exists
if [ ! -f "spark/$SCRIPT" ]; then
    echo "Error: spark/$SCRIPT not found"
    exit 1
fi

echo "Submitting spark/$SCRIPT to Docker Spark cluster..."

# Build spark-submit command with optional quiet mode
if [ "$QUIET" = true ]; then
    echo "(Running in quiet mode - only showing job output)"
    LOG_CONFIG="--conf spark.root.loglevel=WARN"
else
    LOG_CONFIG=""
fi

# Submit the job using docker exec with the mounted volume
# The spark folder is mounted at /opt/spark/work-dir/spark
docker exec spark-master /opt/spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --executor-memory ${SPARK_EXECUTOR_MEMORY:-2g} \
    --executor-cores ${SPARK_EXECUTOR_CORES:-2} \
    --conf spark.pyspark.python=python3 \
    --conf spark.pyspark.driver.python=python3 \
    $LOG_CONFIG \
    /opt/spark/work-dir/spark/$SCRIPT

echo "Job completed!"