#!/usr/bin/env python
"""
Prefect utility script for managing flows and deployments

Usage:
    python prefect_utils.py deploy-all     # Deploy all flows
    python prefect_utils.py list           # List flows and deployments
    python prefect_utils.py run <flow>     # Run a specific flow
"""
import os
import sys
import asyncio
from pathlib import Path
import importlib.util

# Try to import config, but use defaults if not available
try:
    from config import PREFECT_API_URL
except ImportError:
    PREFECT_API_URL = os.environ.get("PREFECT_API_URL", "http://localhost:4200/api")

os.environ["PREFECT_API_URL"] = PREFECT_API_URL

from prefect import get_client, flow
from prefect.deployments import Deployment


def discover_flows(flows_dir="flows"):
    """Discover all flows in the flows directory"""
    flows_path = Path(flows_dir)
    discovered_flows = []

    for py_file in flows_path.glob("*.py"):
        if py_file.name.startswith("_"):
            continue

        module_name = py_file.stem
        spec = importlib.util.spec_from_file_location(f"flows.{module_name}", py_file)

        if spec and spec.loader:
            module = importlib.util.module_from_spec(spec)
            sys.modules[f"flows.{module_name}"] = module
            spec.loader.exec_module(module)

            # Find flows in module
            import inspect
            for name, obj in inspect.getmembers(module):
                if hasattr(obj, "__class__") and obj.__class__.__name__ == "Flow":
                    discovered_flows.append({
                        "flow": obj,
                        "module": module_name,
                        "function": name,
                    })

    return discovered_flows


def deploy_all():
    """Deploy all discovered flows"""
    # Import specific flows with their correct names
    from flows.sample_pipeline import sample_etl_pipeline
    from flows.kaggle_data_prep import kaggle_etl_pipeline
    from flows.parquet_integration import parquet_integration_flow
    from flows.spark_integration_flow import spark_integration_flow

    flows = [
        (sample_etl_pipeline, "sample-etl-pipeline", ["etl", "sample"]),
        (kaggle_etl_pipeline, "kaggle-data-pipeline", ["kaggle", "etl"]),
        (parquet_integration_flow, "parquet-integration", ["parquet"]),
        (spark_integration_flow, "spark-analytics", ["spark", "analytics"]),
    ]

    print("Deploying all flows...")
    for flow_obj, name, tags in flows:
        deployment = flow_obj.to_deployment(name=name, tags=tags)
        deployment_id = deployment.apply()
        print(f"✓ Deployed: {name}")

    print("\n✅ All flows deployed!")
    print("View at: http://localhost:4200/deployments")


async def list_flows_and_deployments():
    """List all flows and deployments"""
    async with get_client() as client:
        # Get flows
        flows = await client.read_flows()
        print(f"\n📊 FLOWS ({len(flows)} total):")
        for f in flows:
            print(f"  - {f.name}")

        # Get deployments
        deployments = await client.read_deployments()
        print(f"\n🚀 DEPLOYMENTS ({len(deployments)} total):")
        for d in deployments:
            print(f"  - {d.name}")

        # Get recent runs
        runs = await client.read_flow_runs(limit=5)
        if runs:
            print(f"\n⏱️  RECENT RUNS:")
            for r in runs:
                print(f"  - {r.name} ({r.state_name})")

        print(f"\n🔗 View UI: http://localhost:4200")


def run_flow(flow_name):
    """Run a specific flow by name"""
    flows = discover_flows()

    for flow_info in flows:
        if flow_info["function"] == flow_name or flow_info["module"] == flow_name:
            print(f"Running {flow_info['module']}.{flow_info['function']}...")
            try:
                result = flow_info["flow"]()
                print(f"✓ Flow completed: {result}")
            except Exception as e:
                print(f"✗ Flow failed: {e}")
            return

    print(f"Flow '{flow_name}' not found")


def main():
    """Main CLI handler"""
    if len(sys.argv) < 2:
        print(__doc__)
        return

    command = sys.argv[1]

    if command == "deploy-all":
        deploy_all()
    elif command == "list":
        asyncio.run(list_flows_and_deployments())
    elif command == "run" and len(sys.argv) > 2:
        run_flow(sys.argv[2])
    else:
        print(__doc__)


if __name__ == "__main__":
    main()