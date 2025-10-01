#!/usr/bin/env python
"""
Setup Python path for the project by creating a .pth file in the virtual environment.
This allows importing from the project root without PYTHONPATH manipulation.
"""
import os
import sys
import site
from pathlib import Path


def setup_python_path():
    """Create a .pth file in the site-packages directory to add project root to Python path."""

    # Get project root (parent of scripts directory)
    project_root = Path(__file__).parent.parent.absolute()

    # Get site-packages directory
    site_packages = site.getsitepackages()
    if not site_packages:
        print("Error: Could not find site-packages directory")
        print("Make sure you're running this script within the virtual environment")
        return False

    site_packages_dir = Path(site_packages[0])

    # Create .pth file
    pth_file = site_packages_dir / "itmx_kaggle.pth"

    try:
        with open(pth_file, 'w') as f:
            f.write(str(project_root))
        print(f"✓ Created {pth_file}")
        print(f"✓ Added project root to Python path: {project_root}")

        # Test that it works
        sys.path.insert(0, str(project_root))
        try:
            import config
            print("✓ Successfully imported config module")
            return True
        except ImportError as e:
            print(f"✗ Failed to import config module: {e}")
            return False

    except Exception as e:
        print(f"✗ Error creating .pth file: {e}")
        return False


if __name__ == "__main__":
    success = setup_python_path()
    sys.exit(0 if success else 1)