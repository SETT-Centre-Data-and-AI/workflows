# Repo Workflow Template

Copy this `.github/workflows` folder into the repository root.

This template is for external adopter repositories.
Do not use it in `SETT-Centre-Data-and-AI/workflows` or `SETT-Centre-Data-and-AI/workflows_development`; those internal workflow repositories should call their local orchestrator path instead.

The path in this template is:

`repo_template/.github/workflows`

After copying, remove the outer `repo_template` folder so the target repository contains:

`/.github/workflows/orchestrator.yaml`
`/.github/workflows/sync-from-public.yaml`
`/.github/workflows/pre-install.sh`
`/.github/workflows/README.md`

What to edit:

- `orchestrator.yaml`
  - set `package-name`
  - set `package-slug`
  - set `private-repo` and/or `public-repo`
  - optionally set `publish-on-release: 'false'`
  - optionally set `test-matrix-json`

- `sync-from-public.yaml`
  - set `private-repo`
  - set `public-repo`

- `pre-install.sh`
  - keep only if tests need extra setup
  - delete it if it is not needed

Required secrets:

- `MANAGEMENT_TOKEN` for sync workflows
- `PYPI_TOKEN` for publish workflow

Optional repo variable:

- `PUBLISH_ON_RELEASE=false`

No other GitHub variables are required.
