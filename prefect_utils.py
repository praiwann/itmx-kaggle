#!/usr/bin/env python
"""
Prefect utility script for managing flows and deployments

This script automatically discovers all Prefect flows in the flows/ directory
and deploys them without needing to hardcode flow names.

Usage:
    python prefect_utils.py deploy-all     # Deploy all flows (auto-discovered)
    python prefect_utils.py list           # List flows and deployments
    python prefect_utils.py run <flow>     # Run a specific flow

The script will find any function decorated with @flow in the flows/ directory.
"""
import os
import sys
import asyncio
from pathlib import Path
import importlib.util

# Ensure project root is in Python path for imports
project_root = Path(__file__).parent.absolute()
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

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

    if not flows_path.exists():
        print(f"Warning: {flows_dir} directory not found")
        return discovered_flows

    for py_file in flows_path.glob("*.py"):
        if py_file.name.startswith("_") or py_file.name == "__init__.py":
            continue

        module_name = py_file.stem
        spec = importlib.util.spec_from_file_location(f"flows.{module_name}", py_file)

        if spec and spec.loader:
            try:
                module = importlib.util.module_from_spec(spec)
                sys.modules[f"flows.{module_name}"] = module
                spec.loader.exec_module(module)

                # Find flows in module using Prefect's flow decorator
                import inspect
                from prefect import Flow

                for name, obj in inspect.getmembers(module):
                    # Check if it's a Prefect flow (has __prefect_flow__ attribute or is Flow instance)
                    if (hasattr(obj, "__prefect_flow__") or
                        (hasattr(obj, "__class__") and (obj.__class__.__name__ == "Flow" or isinstance(obj, Flow)))):
                        # Get the flow's configured name if available
                        flow_name = getattr(obj, 'name', name) if hasattr(obj, 'name') else name
                        discovered_flows.append({
                            "flow": obj,
                            "module": module_name,
                            "function": name,
                            "flow_name": flow_name,  # The name from @flow decorator
                        })
                        print(f"  Found flow: {flow_name} ({module_name}.{name})")
            except Exception as e:
                print(f"Error loading {py_file}: {e}")

    return discovered_flows


def deploy_all():
    """Deploy all discovered flows"""
    discovered_flows = discover_flows()

    if not discovered_flows:
        print("❌ No flows found in flows/ directory")
        return

    print(f"Found {len(discovered_flows)} flow(s) to deploy...")

    for flow_info in discovered_flows:
        flow_obj = flow_info["flow"]
        module_name = flow_info["module"]
        function_name = flow_info["function"]

        # Generate deployment name from module and function
        deployment_name = f"{module_name}-{function_name}".replace("_", "-")

        # Generate tags from module name
        tags = module_name.split("_") + [function_name.split("_")[0]]

        try:
            deployment = flow_obj.to_deployment(
                name=deployment_name,
                tags=tags,
                description=f"Auto-deployed from {module_name}.py"
            )
            deployment.apply()
            print(f"✓ Deployed: {deployment_name} ({module_name}.{function_name})")
        except Exception as e:
            print(f"✗ Failed to deploy {deployment_name}: {e}")

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

    if not flows:
        print("No flows found in flows/ directory")
        return

    # Try to find the flow by various naming patterns
    for flow_info in flows:
        module_name = flow_info["module"]
        function_name = flow_info["function"]
        decorated_flow_name = flow_info.get("flow_name", function_name)
        deployment_name = f"{module_name}-{function_name}".replace("_", "-")

        # Check various possible names (including the decorated flow name)
        if (flow_name == decorated_flow_name or
            flow_name == function_name or
            flow_name == module_name or
            flow_name == deployment_name or
            flow_name == f"{module_name}_{function_name}" or
            flow_name.replace("-", "_") == function_name or
            flow_name.replace("_", "-") == decorated_flow_name):
            print(f"Running flow '{decorated_flow_name}' ({module_name}.{function_name})...")
            try:
                result = flow_info["flow"]()
                print(f"✓ Flow completed successfully")
                return
            except Exception as e:
                print(f"✗ Flow failed: {e}")
                return

    # If not found, show available flows
    print(f"Flow '{flow_name}' not found. Available flows:")
    for flow_info in flows:
        decorated_name = flow_info.get("flow_name", flow_info["function"])
        print(f"  - {decorated_name} (function: {flow_info['function']} in {flow_info['module']}.py)")
        deployment_name = f"{flow_info['module']}-{flow_info['function']}".replace("_", "-")
        print(f"    Deployment name: {deployment_name}")


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