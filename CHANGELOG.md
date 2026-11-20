# Changelog

## Unreleased

First release: a shared lifecycle for my projects' justfiles.

- Phases `setup`, `check`, `test`, `package`, `verify` and `publish`. Each runs goals, which projects redefine to change
  what the phase does.
- Shared goals `pre-test`, `run-tests`, `clean` and `worktree`, in every recipe file that implements the phases.
- Available recipes (each documented in their files)
  - `recipes/python-uv.just`: for uv projects (ruff, basedpyright, pytest, coverage, import-linter, pip audit).
    Includes publishing (stable and release candidates) with GitHub releases and git tags.
  - `recipes/npm.just`: for npm projects, each goal running its package.json script (without `publish`).
  - `recipes/worktree.just`, imported by the others: `worktree <name>`, an unbound goal, creates a git worktree.
- Skill `start-worktree`: names a worktree for a task and runs `just worktree`.
- Reusable GitHub workflows for uv projects: `python-uv-ci.yml` runs `verify`, `python-uv-release.yml` runs `publish`.
  Both install the apt packages in `system_packages` first.
