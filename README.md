<p align="center">
  <img src="docs/images/workflows.png" alt="DAIR CI/CD Workflows" width="300">
</p>

# DAIR CI/CD Workflows

Centralised reusable GitHub Actions workflows for DAIR repositories.

This repository is the orchestration control plane for adopter repositories:
- Enforce consistent CI/CD gates across repositories.
- Enforce release-source policy (for example, private release PRs must come from main).
- Drive private-to-public sync and publish flows.
- Act as the certification testbed before rolling workflow changes org-wide.

## What Is Implemented

- Orchestrator entrypoint: [.github/workflows/workflow-orchestrator.yaml](.github/workflows/workflow-orchestrator.yaml)
- Centralised config contract: [.github/workflows/config.yaml](.github/workflows/config.yaml)
- Policy workflow: [.github/workflows/ensure-private-release-from-main.yaml](.github/workflows/ensure-private-release-from-main.yaml)
- Policy workflow: [.github/workflows/ensure-public-release-from-incoming.yaml](.github/workflows/ensure-public-release-from-incoming.yaml)
- Policy workflow: [.github/workflows/pre-release-version-check.yaml](.github/workflows/pre-release-version-check.yaml)
- Promotion workflow: [.github/workflows/back-sync-release-to-main.yaml](.github/workflows/back-sync-release-to-main.yaml)
- Promotion workflow: [.github/workflows/sync-to-public.yaml](.github/workflows/sync-to-public.yaml)
- Promotion workflow: [.github/workflows/publish-to-pypi.yaml](.github/workflows/publish-to-pypi.yaml)

## Resource Guides

- [Installation and setup](docs/installation-guide.md)
- [Usage and downstream integration](docs/usage-guide.md)
- [Organisation setup and rulesets](docs/ORG_SETUP_GUIDE.md)
- [Deployment patterns](docs/DEPLOYMENT_PATTERNS.md)
- [Testbed validation](docs/TESTBED.md)
- [Templates for downstream adopters](templates/) — Copyable starter pack with setup script

## Rollout Model

1. Keep this repository as the single source of orchestration logic.
2. In each downstream repository, add one lightweight entry workflow that calls this repository via uses and @release.
3. Enforce required status checks with organisation rulesets.
4. Manage secrets at organisation scope and non-sensitive defaults at organisation variable scope.

**Start here**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for quick overview of what's ready and next steps.

## Reference Strategy

Downstream repositories should consume **stable releases** of this orchestrator.

Default: Use `@release` tag for production.
- `@release` — stable, tested version
- `@main` — development version (use only in this repo during development)

**For downstream repos**: Copy one of the starter templates from [templates/](templates/) and follow [templates/README.md](templates/README.md).

Quick start: `bash <(curl -fsSL https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/release/templates/setup.sh) private-only`

## Dispatch Map

- Private PR to main (opened, reopened, synchronize): runs build and test.
- Private PR to release (opened, reopened, synchronize): runs private source-branch policy and version bump check.
- Private PR merge to release with head main: runs back-sync and sync-to-public.
- Public PR to release (opened, reopened, synchronize): runs public source-branch policy and version bump check.
- Public PR merge to release with head incoming_from_private: runs publish-to-pypi.
- Manual run on private release: runs back-sync and sync-to-public.
- Manual run on public release: runs publish-to-pypi.

## Workflow Index

### [.github/workflows/build-and-test.yaml](.github/workflows/build-and-test.yaml)
Purpose: Build package and run smoke and matrix tests.

### [.github/workflows/ensure-private-release-from-main.yaml](.github/workflows/ensure-private-release-from-main.yaml)
Purpose: Enforce private release PR source branch policy.

### [.github/workflows/ensure-public-release-from-incoming.yaml](.github/workflows/ensure-public-release-from-incoming.yaml)
Purpose: Enforce public release PR source branch policy.

### [.github/workflows/pre-release-version-check.yaml](.github/workflows/pre-release-version-check.yaml)
Purpose: Ensure version bump for release PRs.

### [.github/workflows/back-sync-release-to-main.yaml](.github/workflows/back-sync-release-to-main.yaml)
Purpose: Create or reuse release-to-main PR in private repository and enable auto-merge.

### [.github/workflows/sync-to-public.yaml](.github/workflows/sync-to-public.yaml)
Purpose: Mirror private release to public incoming and create or reuse PR to public release.

### [.github/workflows/publish-to-pypi.yaml](.github/workflows/publish-to-pypi.yaml)
Purpose: Build and publish package from public release branch.

### [.github/workflows/sync-from-public.yaml](.github/workflows/sync-from-public.yaml)
Purpose: Manual sync from selected public branch to private incoming, then PR to private main.

## Licence

This work is licensed under [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).

## Authors

DAIR Workflows was developed by Cai Davis at University Hospital Southampton NHS Foundation Trust's Data and AI Research Unit (DAIR), part of the Southampton Emerging Therapies and Technology Centre.

<p align="center">
  <a href="https://github.com/SETT-Centre-Data-and-AI">
    <img src="docs/images/SETT Header.png" alt="NHS UHS SETT Centre">
  </a>
</p>
