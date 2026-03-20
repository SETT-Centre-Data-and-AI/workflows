# Installation and Setup Guide

This repository is primarily a GitHub Actions workflow orchestration repository.
There is no required runtime package installation for downstream use.

## 1. Prepare This Repository

1. Clone the repository.
2. Install development dependencies:

```bash
uv sync --group dev
```

3. Development workflow: Edit `.github/workflows/` files and test via `self-orchestrator.yaml` (local calls to your working branch).
4. When validated, commit changes to a branch and open a PR.
5. After merge to `main`, create a git tag and release (e.g., `v0.2.0`) — downstream repos will pin to `@release` tag.

## 2. Create Organisation-Level Secrets

Create these as organisation secrets with selected-repository access:

- `REPO_SYNC_TOKEN`
- `PYPI_TOKEN`

Notes:
- `REPO_SYNC_TOKEN` should have minimum scopes required for cross-repo branch sync and PR operations.
- `PYPI_TOKEN` should be scoped to publishing only.

## 3. Create Organisation-Level Variables

Set non-sensitive defaults as organisation variables (and allow repo overrides only where needed):

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

## 4. Configure Organisation Rulesets

Configure branch protection/rulesets to require check contexts emitted by your orchestrator jobs.
At minimum, require checks that represent:

- Build and test
- Private release source validation
- Public release source validation
- Pre-release version validation

## 5. Downstream Repositories

Each downstream repository should only need:

1. A minimal workflow that calls your orchestrator via `uses` and `@main`.
2. Optional repo-level variables for approved overrides.
3. No duplicated policy workflow logic.

See [usage-guide.md](usage-guide.md) for caller workflow examples and [DEPLOYMENT_PATTERNS.md](DEPLOYMENT_PATTERNS.md) for setup patterns by repo type.
