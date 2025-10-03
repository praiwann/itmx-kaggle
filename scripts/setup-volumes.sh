#!/bin/bash

# Setup script for Docker named volumes
# This ensures proper filesystem support for DuckDB multi-threading

set -e

echo "🚀 Setting up Docker volumes for ITMX Kaggle pipeline..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

echo ""
echo "📦 Creating named volumes..."

# Create named volumes
docker volume create itmx-duckdb-data 2>/dev/null && echo -e "${GREEN}✓${NC} Created itmx-duckdb-data volume" || echo -e "${YELLOW}⚠${NC} itmx-duckdb-data volume already exists"
docker volume create itmx-spark-work 2>/dev/null && echo -e "${GREEN}✓${NC} Created itmx-spark-work volume" || echo -e "${YELLOW}⚠${NC} itmx-spark-work volume already exists"
docker volume create itmx-dbt-artifacts 2>/dev/null && echo -e "${GREEN}✓${NC} Created itmx-dbt-artifacts volume" || echo -e "${YELLOW}⚠${NC} itmx-dbt-artifacts volume already exists"

echo ""
echo "📁 Ensuring data directories exist..."

# Create data directories for bind mounts
mkdir -p data/raw/kaggle && echo -e "${GREEN}✓${NC} Created data/raw/kaggle"
mkdir -p data/processed && echo -e "${GREEN}✓${NC} Created data/processed"

# Check if MulDiGraph.pkl exists
if [ -f "data/raw/kaggle/MulDiGraph.pkl" ]; then
    echo -e "${GREEN}✓${NC} MulDiGraph.pkl found in data/raw/kaggle/"
else
    echo -e "${YELLOW}⚠${NC} MulDiGraph.pkl not found in data/raw/kaggle/"
    echo "   Please download and place the Kaggle dataset there"
fi

echo ""
echo "🔍 Checking volume status..."

# List volumes with details
echo "Named volumes:"
docker volume ls | grep itmx || echo "No ITMX volumes found"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Ensure MulDiGraph.pkl is in data/raw/kaggle/"
echo "  2. Run: docker-compose up -d"
echo "  3. Deploy flows: make prefect-deploy"
echo "  4. Run pipeline: make pipeline"
echo ""
echo "💡 Tips:"
echo "  - DuckDB can now use multiple threads (DBT_THREADS=4)"
echo "  - Data in named volumes persists even after container removal"
echo "  - To backup DuckDB: docker run --rm -v itmx-duckdb-data:/data alpine tar czf - /data > backup.tar.gz"