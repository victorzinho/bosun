# The phases (README.md) for uv projects.
#
# Tooling: ruff, basedpyright, pytest; optional: pytest-cov, import-linter, pip-audit; git and gh for `publish`.
#
# Phases and the goals they run, in order:
#
#   setup    install
#   check    setup, process-resources, lint, typecheck, lint-imports, audit
#   test     setup, process-resources, pre-test, run-tests
#   package  setup, process-resources, build
#   verify   check, test, package
#   publish  the release version, verify, its commit and tag, the next version, push, release
#
# Goals:
#
# - `process-resources`, `pre-test`: empty.
# - `lint-imports`: only if pyproject.toml configures importlinter.
# - `audit`: pip-audit, if installed.
# - `run-tests`: arguments go to pytest; without them, with --cov if pyproject.toml configures coverage.
# - `build`: the wheel and sdist.
# - `release`: the GitHub release of the latest tag, with dist/* and its CHANGELOG.md section.
# - `clean`: removes dist/; bound to no phase.
# - `worktree`: bound to no phase; recipes/worktree.just.
#
# Variables, to redefine in the project's justfile:
#
# - `audit_ignore`: vulnerability IDs `audit` accepts, space-separated, e.g. "PYSEC-2026-311 GHSA-xxxx-xxxx-xxxx".
# - `uv_group`: the dependency group `install` syncs and the goals run with; "dev" by default.
#
# CI: .github/workflows/python-uv-ci.yml runs `verify`, python-uv-release.yml runs `publish`.
#
# Releasing: pyproject.toml's `version` is always the next release (X.Y.Z.devN or X.Y.ZrcN), and the commit that
# needs a bigger bump makes it. Changes go under CHANGELOG.md's `## Unreleased`.
#
# - `publish stable` releases X.Y.Z with the Unreleased section as its own, then sets X.Y+1.0.dev0.
# - `publish rc` releases the next release candidate with the Unreleased section as notes, then sets the one after it.
# - Both verify the release version and tag it vX.Y.Z[rcN], then push before `release`.

import 'worktree.just'

# Runs a src/bosun module with the system python3, e.g. `{{ _bosun }}has_tool coverage`.
_bosun := "PYTHONPATH=" + quote(source_directory() / ".." / "src") + " python3 -P -m bosun."

# Vulnerability IDs `audit` accepts, space-separated.
audit_ignore := ""

uv_group := "dev"

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

# setup, process-resources, pre-test, run-tests
[group('phases')]
test: setup process-resources pre-test run-tests

# setup, process-resources, build
[group('phases')]
package: setup process-resources build

# check, test, package
[group('phases')]
verify: check test package

# release version, verify, its commit and tag, next version, push, release; CI only
[arg('type', pattern='rc|stable')]
[group('phases')]
publish type: (_release-version type) verify _tag-release (_next-version type) _push release

# uv sync, with the dev group.
[group('goals')]
install:
    uv sync --locked --group {{ uv_group }}

# Generate or process what check and test need.
[group('goals')]
process-resources:

# ruff check.
[group('goals')]
lint:
    uv run --locked --group {{ uv_group }} ruff check

# basedpyright.
[group('goals')]
typecheck:
    uv run --locked --group {{ uv_group }} basedpyright

# import-linter, if pyproject.toml configures it.
[group('goals')]
lint-imports:
    #!/usr/bin/env bash
    set -euo pipefail
    if {{ _bosun }}has_tool importlinter; then
        uv run --locked --group {{ uv_group }} lint-imports
    fi

# pip-audit on uv.lock, if installed.
[group('goals')]
audit:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v pip-audit >/dev/null; then
        uv export --group {{ uv_group }} --frozen --no-emit-project --quiet \
            | pip-audit -r /dev/stdin --disable-pip --require-hashes --progress-spinner=off \
                {{ prepend('--ignore-vuln=', audit_ignore) }}
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
    uv run --locked --group {{ uv_group }} pytest "${coverage[@]}" "$@"

# uv build: the wheel and sdist.
[group('goals')]
build:
    uv build

# Remove dist/.
[group('goals')]
clean:
    rm -rf dist

# The GitHub release of the latest tag, with dist/* and its CHANGELOG.md section.
[group('goals')]
release:
    #!/usr/bin/env bash
    set -euo pipefail
    tag=$(git describe --tags --abbrev=0)
    prerelease=()
    if [[ ! "${tag#v}" =~ ^[0-9.]+$ ]]; then prerelease=(--prerelease); fi
    shopt -s nullglob
    gh release create "$tag" dist/* --verify-tag --notes "$({{ _bosun }}changelog notes "${tag#v}")" "${prerelease[@]}"

# Set the version to release.
_release-version type:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ type }}" == stable ]]; then
        uv version --bump stable --no-sync
        {{ _bosun }}changelog release "$(uv version --short --frozen)"
    elif [[ "$(uv version --short --frozen)" == *.dev* ]]; then
        # from rcN, _next-version already set rcN+1
        uv version --bump rc --no-sync
    fi

# Commit and tag the version to release.
_tag-release:
    #!/usr/bin/env bash
    set -euo pipefail
    version=$(uv version --short --frozen)
    git diff --quiet || git commit -am "Release $version"
    git tag -m "Release $version" "v$version"

# Set the version after the release, then commit it.
_next-version type:
    uv version {{ if type == "stable" { "--bump minor --bump dev=0" } else { "--bump rc" } }} --no-sync
    git commit -am "Prepare $(uv version --short --frozen)"

_push:
    git push --atomic origin HEAD "$(git describe --tags --abbrev=0)"
