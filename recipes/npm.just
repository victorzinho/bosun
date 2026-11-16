# The phases (README.md) for npm projects, without `publish`.
#
# Tooling: npm. Each goal runs the package.json script with its name, if there is one; without it, the goal does
# nothing.
#
# Phases and the goals they run, in order:
#
#   setup    install
#   check    setup, process-resources, lint, typecheck
#   test     setup, process-resources, pre-test, build, test-build, post-test
#   verify   check, test
#   package  verify, build
#
# Goals:
#
# - `install`: npm ci; not a script.
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

# setup, process-resources, pre-test, build, test-build, post-test; arguments go to test-build
[group('phases')]
[positional-arguments]
test *args: setup process-resources pre-test build && post-test
    @{{ just_executable() }} --justfile {{ quote(justfile()) }} test-build "$@"

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

# Start what the tests need.
[group('goals')]
pre-test:
    npm run --if-present pre-test

# Build what gets released.
[group('goals')]
build:
    npm run --if-present build

# Check the build.
[group('goals')]
[positional-arguments]
test-build *args:
    npm run --if-present test-build -- "$@"

# Stop what pre-test started; ideally idempotent.
[group('goals')]
post-test:
    npm run --if-present post-test
