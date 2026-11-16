---
name: start-worktree
description: "Names a git worktree for a new task and creates it beside the repository with `just worktree`. Invoke when starting fresh work in a repository."
---

# Start Worktree

## Step 1 — Inputs

Get from session context, asking for whatever is missing:

- `<repo>`: the path of the repository to branch from.
- The task: a Jira key, a description, or both.

## Step 2 — Name

`<words>`: 2–4 kebab-case English words from the task. Under ~50 chars.

- Jira key given → `<KEY>-<words>`.
- Otherwise → `<words>`.

## Step 3 — Confirm

**STOP** and present:

```
Name (branch and folder): <name>
Worktree:                 <repo>/../<name>
Base:                     the default branch of <repo>
```

Wait for confirmation or another name given.

## Step 4 — Create

Run `just worktree <name>` from `<repo>`.

It fails before creating anything if `<repo>/../<name>` exists or the repository has no default branch: surface the
error and stop. Never reuse or remove an existing worktree.

Once the worktree is created it runs `just verify` there; a failed verify leaves the worktree in place.

## Step 5 — Report

```
Worktree: <repo>/../<name>
Branch:   <name>
Verify:   passed | failed: <last lines of output>
```
