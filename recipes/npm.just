# The phases (README.md) for npm projects, without `publish`.
#
# Tooling: npm. Each goal runs npm's usual script for it, else the package.json script with its name; without the
# script, the goal does nothing.
#
# Phases and the goals they run, in order:
#
#   setup    install
#   check    setup, process-resources, lint, typecheck
#   test     setup, process-resources, pre-test, run-tests, build, test-build, post-test
#   verify   check, test
#   package  verify, build
#
# Goals:
#
# - `install`: npm ci; not a script.
# - `pre-test`, `post-test`: the `pretest` and `posttest` scripts.
# - `run-tests`: the `test` script, without its `pretest` and `posttest` hooks; arguments go to it.
# - `test-build`: checks the build; arguments go to its script.
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

# setup, process-resources, pre-test, run-tests, build, test-build, post-test
[group('phases')]
test: setup process-resources pre-test run-tests build test-build && post-test

# check, test
[group('phases')]
verify: check test

# verify, build
[group('phases')]
package: verify build

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

# Stop what pre-test started; idempotent.
[group('goals')]
post-test:
    npm run --if-present posttest
