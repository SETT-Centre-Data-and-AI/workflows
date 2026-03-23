# Installation and Setup Guide

This repository is primarily a GitHub Actions workflow orchestration repository.
There is no required runtime package installation for downstream use.

## 1. Prepare This Repository

1. Clone the repository.
2. Install development dependencies:

```bash
uv sync --group dev
```

3. Development workflow: edit `.github/workflows/` files and test via `self-orchestrator.yaml` (local calls to the working branch).
4. When validated, commit changes to a branch and open a PR.
5. After merge to `main`, create a git tag and release (e.g., `v0.2.0`) — downstream repos will pin to `@release` tag.

## 2. Create Organisation-Level Secrets

Create these as organisation secrets with selected-repository access:

- `MANAGEMENT_TOKEN`
- `PYPI_TOKEN`

Notes:
- `MANAGEMENT_TOKEN` should have minimum scopes required for cross-repo branch sync and PR operations.
- `PYPI_TOKEN` should be scoped to publishing only.

## 3. Configure Non-Secret Settings in Caller Workflow

Set non-secret configuration directly in each downstream repo's `.github/workflows/ci-orchestrator.yaml` using the `with:` block.

Required values:
- `package-name`
- `package-slug`
- `private-repo` and/or `public-repo`

Optional overrides:
- branch names (`private-repo-main-branch`, `public-repo-release-branch`, etc.)
- runtime versions (`build-smoke-python-version`, `version-check-python-version`, `publish-python-version`)
- `test-matrix-json` (compact inline JSON)
- publish toggle (`publish-on-release: 'false'`)

Optional repo variable fallback:
- `PUBLISH_ON_RELEASE=true|false`

## 4. Configure Organisation Rulesets

Configure branch protection/rulesets to require check contexts emitted by the orchestrator jobs.
At minimum, require checks that represent:

- Build and test
- Private release source validation
- Public release source validation
- Pre-release version validation

## 5. Downstream Repositories

Each downstream repository should only need:

1. A minimal workflow that calls the orchestrator via `uses` and `@release`.
2. Explicit `with:` inputs for package/repo identity.
3. Optional inline overrides in the same workflow file.
4. No duplicated policy workflow logic.

See [usage-guide.md](usage-guide.md) for caller workflow examples and [DEPLOYMENT_PATTERNS.md](DEPLOYMENT_PATTERNS.md) for setup patterns by repo type.
