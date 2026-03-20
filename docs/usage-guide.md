# Usage Guide

Back to [README](../README.md).

## Goal

Use this repository as a centralised reusable workflow orchestrator for all adopter repositories.

## Downstream Caller Workflow

Use the templates in [templates/](../../templates/) for fastest setup.

**Quick start**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/release/templates/setup.sh) private-only
```

Or manually copy the appropriate example:

Reference template: [docs/examples/downstream-ci-orchestrator.yaml](examples/downstream-ci-orchestrator.yaml)

```yaml
name: CI Orchestrator Entry

on:
	pull_request:
		branches: ['**']
		types: [opened, reopened, synchronize, closed]
	workflow_dispatch: {}

permissions:
	contents: write
	pull-requests: write

jobs:
	call-central-orchestrator:
		uses: SETT-Centre-Data-and-AI/workflows/.github/workflows/workflow-orchestrator.yaml@release
		with:
			event-name: ${{ github.event_name }}
			event-action: ${{ github.event.action || '' }}
			base-ref: ${{ github.base_ref || '' }}
			head-ref: ${{ github.head_ref || '' }}
			ref-name: ${{ github.ref_name }}
			repository: ${{ github.repository }}
			pr-merged: ${{ github.event.pull_request.merged || false }}
		secrets: inherit
```

Important:
- Use `@release` to consume stable, tested versions of centralised workflows.
- Use `@main` only for pre-release testing in development.
- Tag releases in this repository using semantic versioning.

## Configuration Precedence

The config workflow supports three layers:

1. `workflow_call` inputs (highest priority)
2. Repository/organisation variables (`vars.*`)
3. Built-in defaults in [config](../.github/workflows/config.yaml)

This allows org-wide defaults with selective overrides.

## Where To Store What

Secrets (sensitive):
- Store in organisation secrets with selected-repo access.
- Examples: `REPO_SYNC_TOKEN`, `PYPI_TOKEN`, API tokens.

Variables (non-sensitive):
- Store defaults in organisation variables.
- Store repo-specific override values in repository variables only when needed.

Recommended org variables:

- `PRIVATE_REPO`
- `PRIVATE_REPO_MAIN_BRANCH`
- `PRIVATE_REPO_RELEASE_BRANCH`
- `PRIVATE_REPO_INCOMING_BRANCH`
- `PUBLIC_REPO`
- `PUBLIC_REPO_INCOMING_BRANCH`
- `PUBLIC_REPO_RELEASE_BRANCH`
- `RELEASE_CHECK_REPOS_JSON`
- `BUILD_SMOKE_PYTHON_VERSION`
- `TEST_MATRIX_JSON`
- `VERSION_CHECK_PYTHON_VERSION`
- `PUBLISH_PYTHON_VERSION`

## Required Status Checks Strategy

To enforce policy at org level, use rulesets/branch protection requiring these checks:

- Build and test check(s)
- Private release source-branch check
- Public release source-branch check
- Pre-release version check

This is what prevents bypass by local workflow edits or optional checks.

## Downstream Repo Setup Patterns

Choose your deployment pattern based on your repository type:

- **Private-only**: development only, no public release
- **Private→Public**: core dev in private, controlled public sync
- **Public-only**: public repository with no private mirror

See [DEPLOYMENT_PATTERNS.md](DEPLOYMENT_PATTERNS.md) for setup instructions for each pattern.

## Testbed Usage In This Repository

Use this repository to validate policy behavior before merging workflow changes to `main`:

1. Verify PR to private `release` from non-`main` fails policy check.
2. Verify PR to private `release` from `main` passes policy check.
3. Verify public `release` policy and version bump checks.
4. Verify merge-triggered sync/publish routes.
