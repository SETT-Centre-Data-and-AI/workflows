# Usage Guide

Back to [README](../README.md).

## Goal

Use this repository as a centralised reusable workflow orchestrator for all adopter repositories.

## Downstream Caller Workflow

Use the starter folder in [repo_template/.github/workflows](../repo_template/.github/workflows) for fastest setup.

Copy [repo_template/.github/workflows](../repo_template/.github/workflows) into the downstream repository root, then remove the outer `repo_template` folder.

Manual example:

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

			package-name: your_package
			package-slug: your-package
			private-repo: your-org/your-private-repo
			public-repo: your-org/your-public-repo

			# Optional overrides
			# private-repo-main-branch: main
			# private-repo-release-branch: release
			# private-repo-incoming-branch: incoming_from_public
			# public-repo-release-branch: release
			# public-repo-incoming-branch: incoming_from_private
			# build-smoke-python-version: '3.13'
			# version-check-python-version: '3.12'
			# publish-python-version: '3.13'
			# publish-on-release: 'false'
			# test-matrix-json: '{"include":[{"os":"ubuntu-latest","python-version":"3.13"}]}'
		secrets: inherit
```

Important:
- Use `@release` to consume stable, tested versions of centralised workflows.
- Use `@main` only for pre-release testing in development.
- Tag releases in this repository using semantic versioning.

## Manual Sync From Public (Downstream Repos)

Downstream repositories can include `.github/workflows/sync-from-public.yaml` from the template for manual public-to-private sync.

This wrapper calls the central reusable workflow:

`SETT-Centre-Data-and-AI/workflows/.github/workflows/sync-from-public.yaml@release`

Run it from the Actions tab and provide `public_branch`. In the wrapper file, set:

- `private-repo`
- `public-repo`

## Configuration Precedence

Configuration is resolved once in [workflow-orchestrator](../.github/workflows/workflow-orchestrator.yaml) via [config](../.github/workflows/config.yaml), then routed workflows receive resolved inputs directly.

The config workflow supports two layers:

1. `workflow_call` inputs (highest priority)
2. Built-in defaults in [config](../.github/workflows/config.yaml)

GitHub variables are not required for normal DAIR usage.

## Where To Store What

Secrets (sensitive):
- Store in organisation secrets with selected-repo access.
- `MANAGEMENT_TOKEN` for cross-repo sync workflows.
- `PYPI_TOKEN` for publish workflow.

Non-secrets:
- Store directly in `.github/workflows/ci-orchestrator.yaml` under `with:`.
- Required: `package-name`, `package-slug`, and the applicable repo identity (`private-repo`, `public-repo`, or both).
- Optional: branch names, runtime versions, and `test-matrix-json`.
- Optional publish toggle: `publish-on-release` (`true` or `false`).
- Equivalent repo variable fallback: `PUBLISH_ON_RELEASE=true|false`.

Matrix note:
- `test-matrix-json` is inline JSON input.
- Add compact JSON directly to `test-matrix-json` when a custom matrix is needed.

## System Dependencies and Pre-Install Script

Some packages require system-level libraries (e.g. `libmariadb-dev`, `unixodbc-dev`) or extra Python tooling (e.g. `keyring`) before tests can run.

Place `.github/workflows/pre-install.sh` in the downstream repository when extra setup is required. It is executed automatically after Python and base tooling are installed, before package installation. Use `$RUNNER_OS` to guard platform-specific steps:

```bash
#!/bin/bash
# .github/workflows/pre-install.sh

if [[ "$RUNNER_OS" == "Linux" ]]; then
  sudo apt-get update
  sudo apt-get install -y \
    libmariadb3 libmariadb-dev \
    unixodbc unixodbc-dev
fi

# Extra Python tooling (installed to the activated Python environment)
pip install keyring keyrings.alt
```

See [repo_template/.github/workflows/README.md](../repo_template/.github/workflows/README.md) for the copy procedure. The script is optional; if the file is absent the step is skipped.

## Required Status Checks Strategy

To enforce policy at org level, use rulesets/branch protection requiring these checks:

- Build and test check(s)
- Release source check
- Pre-release version check

This is what prevents bypass by local workflow edits or optional checks.

## Downstream Repo Setup Patterns

Choose the deployment pattern based on repository type:

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
