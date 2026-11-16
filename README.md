# bosun

Shared conventions for working on projects: the lifecycle phases every project's justfile has, the recipes that
implement them, and skills for coding agents.

Requires `just` 1.56 or newer.

## Phases

| Phase     | Does                                             | Depends on      |
|-----------|--------------------------------------------------|-----------------|
| `setup`   | create or sync the environment from the lockfile |                 |
| `check`   | lint, type-check and audit dependencies          | `setup`         |
| `test`    | run the tests; arguments go to the test runner   | `setup`         |
| `verify`  | every gate CI runs                               | `check`, `test` |
| `package` | build what gets released: wheel, image, site     | `verify`        |
| `publish` | release it: `stable` or `rc`; CI only            | `package`       |

A phase only orders earlier phases and goals. Goals do the work and have no dependencies. A goal is bound to zero or
more phases.

## Compatibility

`bosun` guarantees the phases. Each recipe file guarantees its goals, which phase runs them, and its variables.

Changing any of these is a breaking change.

Goals with the same name in two files are a convenience, not a promise.

## Recipes

Each file documents, at its top, its tooling, the goals each phase runs, and what they do.

- `recipes/python-uv.just`: uv projects, released to GitHub with their wheel and sdist.
- `recipes/python-pixi.just`: pixi projects, without `package` and `publish`.
- `recipes/npm.just`: npm projects, each goal running its package.json script; without `publish`.
- `recipes/worktree.just`: creates git worktrees (unbounded goal), imported by the files above.

## Using it

Clone this repo as `~/.config/bosun` and import the recipes from the project's justfile:

```just
import '~/.config/bosun/recipes/python-uv.just'
```

To change what a phase does, redefine its goals in the justfile, below `set allow-duplicate-recipes`; an empty goal
skips it. Never redefine a phase: unlike Maven, goals are rewritten, not rebound.

To change a recipe file's variables, redefine them in the justfile, below `set allow-duplicate-variables`.

Skills live in `skills/<name>/SKILL.md`; link each into the coding agent's skills folder.

In CI, call the reusable workflows at a bosun tag; they get the recipes at that tag. The release one needs
`permissions: contents: write` and a `release_type` (`rc` or `stable`). Both take `system_packages`, apt packages
installed first:

```yaml
jobs:
  ci:
    uses: victorzinho/bosun/.github/workflows/python-uv-ci.yml@<tag>
    with:
      system_packages: libpq-dev gettext
```

## Releasing

bosun keeps `pyproject.toml` and the changelog current: `version` is the next release (`X.Y.Z.devN` or `X.Y.ZrcN`),
and the commit that needs a bigger bump makes it. Changes go under the changelog's `## Unreleased`.

Run the Release workflow from `main`:

- `stable` releases `X.Y.Z` with the Unreleased section as its own, then sets `X.Y+1.0.dev0`.
- `rc` releases the next release candidate with the Unreleased section as notes, then sets the one after it.

It runs `publish` from `recipes/python-uv.just`, through bosun's own `justfile`.
