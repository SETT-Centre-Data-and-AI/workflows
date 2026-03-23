# Usage in Repos

Use this template to set up a downstream repository against the stable workflows release.

Template location:

- `repo_template/.github/workflows`

## Quick Setup

1. Copy `repo_template/.github/workflows` to `/.github/workflows` in your downstream repository.
2. Confirm these files exist:

- `/.github/workflows/orchestrator.yaml`
- `/.github/workflows/sync-from-public.yaml`
- `/.github/workflows/pre-install.sh`
- `/.github/workflows/README.md`

## Configure `orchestrator.yaml`

Set required values:

- `package-name`
- `package-slug`
- `private-repo` and/or `public-repo`

Optional values:

- `publish-on-release: 'true'` if you want publish on public release merges (default is off)
- `test-matrix-json` if you want a custom test matrix
- branch overrides if you do not use `main` and `release`

This file calls the central stable orchestrator:

- `SETT-Centre-Data-and-AI/workflows/.github/workflows/central-orchestrator.yaml@release`

## Configure `sync-from-public.yaml`

Set:

- `private-repo`
- `public-repo`

Use this workflow for manual pullback from a selected public branch to private.

## Optional `pre-install.sh`

Use this script if your tests need extra setup before package install.

## Required Secrets

Set repository or organisation secrets as needed:

- `MANAGEMENT_TOKEN` for cross-repository sync operations
- `PYPI_TOKEN` for publishing from public repositories

No extra repository variables are required for default use.
