# The phases (README.md) for npm projects, without `publish`.
#
# Tooling: npm. Each goal runs npm's usual script for it, else the package.json script with its name; without the
# script, the goal does nothing.
#
# Phases and the goals they run, in order:
#
#   setup    install
#   check    setup, process-resources, lint, typecheck
#   test     setup, process-resources, pre-test, run-tests
#   package  setup, process-resources, build
#   verify   check, test, package, test-build
#
# Goals:
#
# - `install`: npm ci; not a script.
# - `pre-test`: the `pretest` script.
# - `run-tests`: the `test` script, without its `pretest` and `posttest` hooks; arguments go to it.
# - `test-build`: checks the build; arguments go to its script.
# - `clean`: the `clean` script; bound to no phase.
# - `worktree`: bound to no phase; recipes/worktree.just.

import 'worktree.just'

# List the recipes.
[default]
list:
    @{{ just_executable() }} --justfile {{ quote(justfile()) }} --list --unsorted

# install
[group('phases')]
setup: install

# setup, process-resources, lint, typecheck
[group('phases')]
check: setup process-resources lint typecheck

# setup, process-resources, pre-test, run-tests
[group('phases')]
test: setup process-resources pre-test run-tests

# setup, process-resources, build
[group('phases')]
package: setup process-resources build

# check, test, package, test-build
[group('phases')]
verify: check test package test-build

# npm ci.
[group('goals')]
install:
    npm ci

# Generate or process what check and test need.
[group('goals')]
process-resources:
    npm run --if-present process-resources

# Lint the sources.
[group('goals')]
lint:
    npm run --if-present lint

# Type-check the sources.
[group('goals')]
typecheck:
    npm run --if-present typecheck

# Start what the tests need; idempotent.
[group('goals')]
pre-test:
    npm run --if-present pretest

# npm test, without its pretest and posttest hooks; arguments go to it.
[group('goals')]
[positional-arguments]
run-tests *args:
    npm run --if-present --ignore-scripts test -- "$@"

# Build what gets released.
[group('goals')]
build:
    npm run --if-present build

# Check the build; arguments go to its script.
[group('goals')]
[positional-arguments]
test-build *args:
    npm run --if-present test-build -- "$@"

# Remove what the other goals created; idempotent.
[group('goals')]
clean:
    npm run --if-present clean
