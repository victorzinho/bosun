"""Exit 0 if the pyproject.toml in the working directory has a `[tool.<name>]` table, 1 if not.

Usage: python3 -m bosun.has_tool <name>
"""

import sys
import tomllib
from pathlib import Path

PYPROJECT = Path('pyproject.toml')


def has_tool(name: str) -> bool:
    if not PYPROJECT.exists():
        return False
    with PYPROJECT.open('rb') as file:
        return name in tomllib.load(file).get('tool', {})


if __name__ == '__main__':
    sys.exit(0 if has_tool(sys.argv[1]) else 1)
