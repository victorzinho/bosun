# The phases (README.md) for pixi projects, without `package` and `publish`.
#
# Tooling: ruff, basedpyright, pytest; optional: pytest-cov, import-linter, pip-audit.
#
# Phases and the goals they run, in order:
#
#   setup    install
#   check    setup, process-resources, lint, typecheck, lint-imports, audit
#   test     setup, process-resources, pre-test, run-tests, post-test
#   verify   check, test
#
# Goals:
#
# - `process-resources`, `pre-test`, `post-test`: empty.
# - `lint-imports`: only if pyproject.toml configures importlinter.
# - `audit`: pip-audit, if installed.
# - `run-tests`: arguments go to pytest; without them, with --cov if pyproject.toml configures coverage.
# - `worktree`: bound to no phase; recipes/worktree.just.
#
# Variables, to redefine in the project's justfile:
#
# - `audit_ignore`: vulnerability IDs `audit` accepts, space-separated, e.g. "PYSEC-2026-311 GHSA-xxxx-xxxx-xxxx".

import 'worktree.just'

# Runs a src/bosun module with the system python3, e.g. `{{ _bosun }}has_tool coverage`.
_bosun := "PYTHONPATH=" + quote(source_directory() / ".." / "src") + " python3 -P -m bosun."

# Vulnerability IDs `audit` accepts, space-separated.
audit_ignore := ""

# List the recipes.
[default]
list:
    @{{ just_executable() }} --justfile {{ quote(justfile()) }} --list --unsorted

# install
[group('phases')]
setup: install

# setup, process-resources, lint, typecheck, lint-imports, audit
[group('phases')]
check: setup process-resources lint typecheck lint-imports audit

# setup, process-resources, pre-test, run-tests, post-test
[group('phases')]
test: setup process-resources pre-test run-tests && post-test

# check, test
[group('phases')]
verify: check test

# pixi install.
[group('goals')]
install:
    pixi install --locked

# Generate or process what check and test need.
[group('goals')]
process-resources:

# ruff check.
[group('goals')]
lint:
    pixi run --locked ruff check

# basedpyright.
[group('goals')]
typecheck:
    pixi run --locked basedpyright

# import-linter, if pyproject.toml configures it.
[group('goals')]
lint-imports:
    #!/usr/bin/env bash
    set -euo pipefail
    if {{ _bosun }}has_tool importlinter; then
        pixi run --locked lint-imports
    fi

# pip-audit on the installed packages, if installed.
[group('goals')]
audit:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v pip-audit >/dev/null; then
        site_packages=$(pixi run --locked python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
        pip-audit --path "$site_packages" --progress-spinner=off {{ prepend('--ignore-vuln=', audit_ignore) }}
    else
        echo "audit: pip-audit not found, skipping the dependency audit" >&2
    fi

# Start what the tests need; idempotent.
[group('goals')]
pre-test:

# pytest with the arguments; without them, with --cov if pyproject.toml configures coverage.
[group('goals')]
[positional-arguments]
run-tests *args:
    #!/usr/bin/env bash
    set -euo pipefail
    coverage=()
    if [[ $# -eq 0 ]] && {{ _bosun }}has_tool coverage; then coverage=(--cov); fi
    pixi run --locked pytest "${coverage[@]}" "$@"

# Stop what pre-test started; idempotent.
[group('goals')]
post-test:
