# A goal bound to no phase (README.md), imported by other recipe files.
#
# Tooling: git.
#
# Goals:
#
# - `worktree <name>`: a git worktree beside the repository, at ../<name>, on a new branch <name> from the default
#   branch (origin/HEAD, else main, else master). Fails if ../<name> exists. Copies `worktree_files` the worktree
#   lacks, then runs `test` in it.
#
# Variables, to redefine in the project's justfile:
#
# - `worktree_files`: gitignored files and directories copied into a new worktree, space-separated;
#   "AGENTS.md .claude .agents" by default.

# Gitignored files and directories copied into a new worktree, space-separated.
worktree_files := "AGENTS.md .claude .agents"

# A worktree at ../<name> on a new branch from the default branch, then test it.
[group('goals')]
worktree name:
    #!/usr/bin/env bash
    set -euo pipefail
    top=$(git rev-parse --show-toplevel)
    target="$(dirname "$top")"/{{ quote(name) }}
    if [[ -e "$target" ]]; then
        echo "worktree: $target already exists" >&2
        exit 1
    fi
    base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)
    base=${base#origin/}
    for candidate in main master; do
        if [[ -z "$base" ]] && git show-ref --verify --quiet "refs/heads/$candidate"; then base=$candidate; fi
    done
    if [[ -z "$base" ]]; then
        echo "worktree: no default branch: origin/HEAD, main and master are all missing" >&2
        exit 1
    fi
    git worktree add -b {{ quote(name) }} "$target" "$base"
    for file in {{ worktree_files }}; do
        if [[ -e "$top/$file" && ! -e "$target/$file" ]]; then cp -a "$top/$file" "$target/$file"; fi
    done
    cd "$target/$(realpath --relative-to "$top" {{ quote(justfile_directory()) }})"
    {{ just_executable() }} test
