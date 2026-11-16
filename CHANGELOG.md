# Changelog

## Unreleased

First release: a shared lifecycle for my projects' justfiles.

- Phases `setup`, `check`, `test`, `verify`, `package` and `publish`. Each runs goals, which projects redefine to change
  what the phase does.
- Available recipes (each documented in their files)
  - `recipes/python-uv.just`: for uv projects (ruff, basedpyright, pytest, coverage, import-linter, pip audit).
    Includes publishing (stable and release candidates) with GitHub releases and git tags.
  - `recipes/python-pixi.just`: for pixi projects (without `package` and `publish`).
  - `recipes/npm.just`: for npm projects, each goal running its package.json script (without `publish`).
  - `recipes/worktree.just`, imported by the others: `worktree <name>`, an unbound goal, creates a git worktree.
- Skill `start-worktree`: names a worktree for a task and runs `just worktree`.
- Reusable GitHub workflows for uv projects: `python-uv-ci.yml` runs `verify`, `python-uv-release.yml` runs `publish`.
