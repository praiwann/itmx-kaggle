#!/bin/bash

# Verification script for Docker volume setup
# Tests that DuckDB can use multiple threads in the new configuration

set -e

echo "🔍 Verifying Docker volume setup for ITMX Kaggle pipeline..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if services are running
echo "Checking Docker services..."
if docker-compose ps | grep -q "prefect.*Up"; then
    echo -e "${GREEN}✓${NC} Prefect service is running"
else
    echo -e "${RED}✗${NC} Prefect service is not running"
    echo "  Run: make docker-up"
    exit 1
fi

if docker-compose ps | grep -q "spark.*Up"; then
    echo -e "${GREEN}✓${NC} Spark service is running"
else
    echo -e "${YELLOW}⚠${NC} Spark service is not running (optional)"
fi

echo ""
echo "Checking Docker volumes..."

# Check if volumes exist
for volume in itmx-duckdb-data itmx-spark-work itmx-dbt-artifacts; do
    if docker volume ls | grep -q "$volume"; then
        echo -e "${GREEN}✓${NC} Volume $volume exists"
    else
        echo -e "${RED}✗${NC} Volume $volume does not exist"
        echo "  Run: make docker-volumes"
        exit 1
    fi
done

echo ""
echo "Testing DuckDB multi-threading capability..."

# Test DuckDB with multiple threads in Prefect container
docker-compose exec -T prefect python -c "
import duckdb
import sys

try:
    # Connect to DuckDB with multiple threads
    conn = duckdb.connect('/data/duckdb/itmx_kaggle.duckdb', config={'threads': 4})

    # Check thread configuration
    result = conn.execute(\"SELECT current_setting('threads')\").fetchone()
    threads = result[0] if result else 'unknown'

    print(f'✓ DuckDB connection successful')
    print(f'✓ Threads configured: {threads}')

    # Create a test table to verify write access
    conn.execute(\"CREATE TABLE IF NOT EXISTS test_threading (id INT, value TEXT)\")
    conn.execute(\"INSERT INTO test_threading VALUES (1, 'test')\")
    count = conn.execute(\"SELECT COUNT(*) FROM test_threading\").fetchone()[0]
    conn.execute(\"DROP TABLE test_threading\")

    print(f'✓ Write/Read test successful')

    conn.close()
    sys.exit(0)
except Exception as e:
    print(f'✗ Error: {e}')
    sys.exit(1)
" && echo -e "${GREEN}✓${NC} DuckDB multi-threading test passed" || echo -e "${RED}✗${NC} DuckDB multi-threading test failed"

echo ""
echo "Testing DBT configuration..."

# Test DBT can connect to DuckDB
docker-compose exec -T prefect bash -c "cd /app/dbt && dbt debug --target docker" > /dev/null 2>&1 && \
    echo -e "${GREEN}✓${NC} DBT configuration is valid" || \
    echo -e "${YELLOW}⚠${NC} DBT configuration needs review"

echo ""
echo "Checking data directories..."

# Check if data directories exist
if [ -d "data/raw/kaggle" ]; then
    echo -e "${GREEN}✓${NC} data/raw/kaggle directory exists"
    if [ -f "data/raw/kaggle/MulDiGraph.pkl" ]; then
        echo -e "${GREEN}✓${NC} MulDiGraph.pkl found"
    else
        echo -e "${YELLOW}⚠${NC} MulDiGraph.pkl not found - pipeline will fail without it"
    fi
else
    echo -e "${RED}✗${NC} data/raw/kaggle directory does not exist"
fi

if [ -d "data/processed" ]; then
    echo -e "${GREEN}✓${NC} data/processed directory exists"
else
    echo -e "${YELLOW}⚠${NC} data/processed directory does not exist"
fi

echo ""
echo "================================"
echo "Verification Summary:"
echo "================================"

all_good=true

# Summary checks
docker-compose ps | grep -q "prefect.*Up" || all_good=false
docker volume ls | grep -q "itmx-duckdb-data" || all_good=false

if [ "$all_good" = true ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo ""
    echo "Your setup is ready. You can now:"
    echo "  1. Deploy flows: make prefect-deploy"
    echo "  2. Run pipeline: make pipeline"
    echo "  3. Run DBT with multiple threads: make dbt THREADS=4"
else
    echo -e "${RED}❌ Some checks failed. Please review the errors above.${NC}"
    exit 1
fi