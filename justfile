import 'recipes/python-uv.just'
set allow-duplicate-recipes

# ruff check, and the recipe files formatted and valid.
[group('redefined-goals')]
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    uv run --locked --group {{ uv_group }} ruff check
    for file in justfile recipes/*.just; do
        just --justfile "$file" --fmt --check || { echo "lint: $file is not formatted, or not valid" >&2; exit 1; }
    done

# Nothing to build: the release is the tag.
[group('redefined-goals')]
build:
