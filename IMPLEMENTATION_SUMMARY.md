# Implementation Summary

## Phase 1: Complete ✓

**Centralised orchestrator infrastructure is ready for use.**

### What's Implemented

#### Core Orchestrator
- **[central-orchestrator.yaml](.github/workflows/central-orchestrator.yaml)**: Main routing control plane
  - Callable reusable workflow invoked by entry workflows
  - Routes to specific validation and promotion workflows
  - Supports `workflow_call` from this repo and downstream repos
  - Accepts caller context (event type, branch names, merge status) so downstream repos can invoke centrally

- **[self-orchestrator.yaml](.github/workflows/self-orchestrator.yaml)**: Development entry point
  - This repository uses its own workflows during development
  - Acts as this repo's only direct PR/manual entry workflow
  - Calls local `central-orchestrator.yaml` instead of published versions
  - Enables testing workflow changes before release

- **[config.yaml](.github/workflows/config.yaml)**: Centralised policy configuration
  - Two-layer resolution: workflow inputs → built-in defaults
  - Exports all configuration for reuse across workflows
  - Fully parameterizable per downstream repo via caller workflow inputs

#### Policy Gates
- **[ensure-release-source.yaml](.github/workflows/ensure-release-source.yaml)**
  - Enforces release PR source route policy:
    - private release requires `main -> release`
    - public release requires `incoming_from_private -> release`
  - **Required status check**: `ensure-release-source`

- **[pre-release-version-check.yaml](.github/workflows/pre-release-version-check.yaml)**
  - Validates version bump in `pyproject.toml` when targeting release branches
  - **Required route/check target**: `pre-release-version-check`

#### Promotion Workflows
- **[back-sync-release-to-main.yaml](.github/workflows/back-sync-release-to-main.yaml)**
  - Maintains sync between release and main branches
  - Auto-creates release→main PR with auto-merge enabled

- **[sync-to-public.yaml](.github/workflows/sync-to-public.yaml)**
  - Mirrors private release to public incoming branch
  - Auto-creates public release PR

- **[publish-to-pypi.yaml](.github/workflows/publish-to-pypi.yaml)**
  - Builds and publishes to PyPI from public release

#### Build & Test
- **[build-and-test.yaml](.github/workflows/build-and-test.yaml)**
  - Builds package and runs test suite
  - Configurable Python version matrix
  - Smoke test + full matrix both supported

### Documentation Complete

| Guide | Purpose | Audience |
|-------|---------|----------|
| [README.md](README.md) | Project overview and quick links | Everyone |
| [installation-guide.md](docs/installation-guide.md) | One-time org setup (secrets, rulesets) | Org admins |
| [usage-guide.md](docs/usage-guide.md) | How to call this orchestrator from downstream repos | Repository maintainers |
| [ORG_SETUP_GUIDE.md](docs/ORG_SETUP_GUIDE.md) | Detailed ruleset configuration and branch protection | Org admins / DevOps |
| [DEPLOYMENT_PATTERNS.md](docs/DEPLOYMENT_PATTERNS.md) | Setup patterns for private-only, private→public, public-only repos | Repository teams |
| [TESTBED.md](docs/TESTBED.md) | How to validate policy behavior before release | Release managers |

### Example Workflows and Templates

- **[docs/examples/](docs/examples/)** — Reference workflows for downstream repos (all pin to `@release`)
  - [downstream-ci-orchestrator.yaml](docs/examples/downstream-ci-orchestrator.yaml) — Universal entry point
  - [downstream-private-only-ci-orchestrator.yaml](docs/examples/downstream-private-only-ci-orchestrator.yaml) — Private-only repo
  - [downstream-private-to-public-ci-orchestrator.yaml](docs/examples/downstream-private-to-public-ci-orchestrator.yaml) — Private-to-public repo

- **[repo_template/](repo_template/)** — Copyable starter package for downstream adopters
  - [repo_template/.github/workflows/ci-orchestrator.yaml](repo_template/.github/workflows/ci-orchestrator.yaml) — Copyable caller workflow
  - [repo_template/.github/workflows/sync-from-public.yaml](repo_template/.github/workflows/sync-from-public.yaml) — Manual downstream wrapper for public-to-private sync
  - [repo_template/.github/workflows/pre-install.sh](repo_template/.github/workflows/pre-install.sh) — Optional custom setup hook
  - [repo_template/.github/workflows/README.md](repo_template/.github/workflows/README.md) — Copy instructions for the folder

---

## Architecture

### Routing Model

```
Downstream Repo Event
    ↓
workflow_call: central-orchestrator.yaml@release   ← Stable release tag
    ↓
  route job reads resolved workflow inputs/defaults
    ↓
  route job evaluates event conditions
    ↓
  route outputs flags: RUN_BUILD, RUN_ENSURE_*, RUN_BACK_SYNC, RUN_SYNC_*, RUN_PUBLISH
    ↓
  conditional jobs call specific workflows with resolved inputs
    ↓
Routed workflows execute directly with inherited secrets
```

### Configuration Resolution

```
Downstream repo calls workflow-orchestrator.yaml with optional inputs
    ↓
workflow-orchestrator.yaml calls config.yaml once
    ↓
  inputs provided?
    Yes → Use it
    No  → Use built-in default
    ↓
Orchestrator passes resolved values to routed workflows
```

### Configuration Scope

**Secrets** (sensitive, org-wide with per-repo access):
- `MANAGEMENT_TOKEN` — cross-repo sync
- `PYPI_TOKEN` — PyPI publishing

**Non-secrets** (in caller workflow `with:` inputs):
- Repository identity and branch names
- Package import/distribution names
- Python runtime overrides
- Optional test matrix JSON

---

## How to Use This (Quick Start)

### 1. Development in This Repository

Workflows in this repository use **self-orchestrator** for testing:

```bash
# Edit workflows
git checkout -b feat/my-workflow-change
# Edit .github/workflows/...

# Self-orchestrator automatically tests workflow changes
# (opens PR, self-orchestrator.yaml calls local workflows)
git commit -am "feat: ..."
git push origin feat/my-workflow-change

# Open PR in GitHub UI
# Expected: self-orchestrator runs and tests routing/policy logic
```

When ready to release:

```bash
# Merge PR to main
git checkout main && git pull
# Tag for release
git tag v0.2.0
git push origin v0.2.0
# Create release in GitHub UI with changelog
```

### 2. Organisation Admin Setup (One-Time)

```bash
# 1. Create org secrets
GitHub UI → Organisation Settings → Secrets and variables → Secrets
  • Add MANAGEMENT_TOKEN (PAT with repo access)
  • Add PYPI_TOKEN (PyPI publish token)

# 2. Configure downstream caller workflow inputs
# Add package/repo identity values in .github/workflows/orchestrator.yaml
# Add optional branch/runtime/test-matrix overrides only where needed

# 3. Configure rulesets
GitHub UI → Organisation Settings → Rulesets
  # Template is in docs/ORG_SETUP_GUIDE.md
```

### 3. Per-Repository Setup (Repeatable)

**For each adopter repo**, copy the template folder for quickest setup:

```bash
# Copy repo_template/.github/workflows into the repository root,
# then remove the outer `repo_template` folder so files end up under .github/workflows.
git add .github/workflows/orchestrator.yaml .github/workflows/pre-install.sh
git commit -m "feat: add centralised CI/CD orchestrator"
git push origin main

# Share access to required secrets
GitHub UI → Repository Settings → Secrets and variables
  # Grant access to MANAGEMENT_TOKEN (if using sync)
  # Grant access to PYPI_TOKEN (if publishing)
```

### 4. Roll Out Workflows

- Test and develop in this repo (via `self-orchestrator.yaml`)
- Tag release when validated
- All downstream repos immediately get latest via `@release` tag

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Self-orchestrator for development | Workflows test themselves; development uses local workflows before release |
| Downstream use `@release` tag | Stable versions; org rolls out tested changes by releasing new tags |
| Centralised routing logic | Single control plane prevents drift; easier to audit |
| Config via caller workflow inputs | Keep behavior visible in code per repo |
| Mandatory private→public pipeline | Enforces consistent release flow; easy opt-out via config |
| Secrets at org scope | Fewer secrets to manage; better auditability |
| Templates for adopters | Fast onboarding; less copy-paste error |

---

## What's NOT Yet Implemented (Backlog)

✗ Automated policy tests in this repo (verify route decisions end-to-end)
✗ Release tags / version management for orchestrator itself
✗ Integration with GitHub Releases API
✗ Rollback workflow for bad releases
✗ Multi-public-repo sync (currently 1:1 private:public)
✗ Slack/email notifications for release events

---

## Status by Phase

| Phase | Status | Details |
|-------|--------|---------|
| **1. Baseline orchestrator** | ✓ Complete | Reusable workflows, routing logic, policy gates, config contract |
| **2. Org setup & enforcement** | ✓ Complete | Rulesets guide, required checks mapped, downstream examples |
| **3. Documentation** | ✓ Complete | Setup, usage, patterns, testbed, org admin guides |
| **4. Testing & validation** | ⏳ In scope | (See Backlog) |
| **5. Rollout sequencing** | 🔜 Next | Pilot with 1-2 repos, measure, expand org-wide |

---

## Next Steps

1. **Review** [ORG_SETUP_GUIDE.md](docs/ORG_SETUP_GUIDE.md) — decide on branch protection strategy
2. **Identify** first 1-2 pilot repos (private-only and/or private→public)
3. **Follow** [DEPLOYMENT_PATTERNS.md](docs/DEPLOYMENT_PATTERNS.md) for pilot setup
4. **Add entry workflow** to pilot repos
5. **Validate** using [TESTBED.md](docs/TESTBED.md) checklist
6. **Iterate** on rulesets/workflow inputs based on pilot feedback
7. **Rollout** to broader organisation with staged enablement

---

## Support and Troubleshooting

- **Routing not working?** → Check [central-orchestrator.yaml](.github/workflows/central-orchestrator.yaml) branch conditions
- **Check not appearing?** → Verify PR matches routing condition; check workflow syntax
- **Merge blocked unexpectedly?** → Verify required check is passing; review [ORG_SETUP_GUIDE.md](docs/ORG_SETUP_GUIDE.md) ruleset config
- **Secret not resolving?** → Confirm secret granted to repository in org settings
- **Variable precedence confusion?** → Refer to [usage-guide.md](docs/usage-guide.md) config layer explanation

---

## Architecture Diagram

```
┌─────────────────────────────────────┐
│  Organisation Configuration         │
│ (Secrets in GitHub)                 │
│  - MANAGEMENT_TOKEN                 │
│  - PYPI_TOKEN                       │
│  - Selected repo access             │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│  This Repository (workflows)        │
│  Central Orchestrator & Testbed     │
│ ┌─────────────────────────────────┐ │
│ │ central-orchestrator.yaml      │ │ ← Entry point (listens to all events)
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ config.yaml                     │ │ ← Config resolution (inputs → built-in defaults)
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Policy & Promotion Workflows    │ │ ← Called by orchestrator
│ │ • ensure-*.yaml                 │ │
│ │ • back-sync, sync-to-public     │ │
│ │ • publish-to-pypi.yaml          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
            ↓
   Uses: SETT-Centre-Data-and-AI/workflows
         /.github/workflows/central-orchestrator.yaml@main
            ↓
┌─────────────────────────────────────┐
│  Downstream Repos (many)            │
│ ┌─────────────────────────────────┐ │
│ │ .github/workflows/              │ │
│ │  orchestrator.yaml           │ │ ← Single file, calls central orchestrator
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

This repository is the centralised CI/CD control plane for DAIR workflows.

Last updated: March 20, 2026
