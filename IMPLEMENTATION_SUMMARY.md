# Implementation Summary

## Phase 1: Complete ✓

**Centralized orchestrator infrastructure is ready for use.**

### What's Implemented

#### Core Orchestrator
- **[workflow-orchestrator.yaml](.github/workflows/workflow-orchestrator.yaml)**: Main routing control plane
  - Listens to PR events and manual dispatches
  - Routes to specific validation and promotion workflows
  - Supports direct repo execution and reusable `workflow_call` from downstream repos
  - Accepts caller context (event type, branch names, merge status) so downstream repos can invoke centrally

- **[self-orchestrator.yaml](.github/workflows/self-orchestrator.yaml)**: Development entry point
  - This repository uses its own workflows during development
  - Calls local `workflow-orchestrator.yaml` instead of published versions
  - Enables testing workflow changes before release

- **[config.yaml](.github/workflows/config.yaml)**: Centralized policy configuration
  - Three-layer resolution: workflow inputs → org variables → built-in defaults
  - Exports all configuration for reuse across workflows
  - Fully parameterizable for org defaults with per-repo overrides

#### Policy Gates
- **[ensure-private-release-from-main.yaml](.github/workflows/ensure-private-release-from-main.yaml)**
  - Enforces private release PRs must originate from main branch
  - **Required status check**: `enforce-private-release-source`

- **[ensure-public-release-from-incoming.yaml](.github/workflows/ensure-public-release-from-incoming.yaml)**
  - Enforces public release PRs must originate from designated incoming branch
  - **Required status check**: `enforce-public-release-source`

- **[pre-release-version-check.yaml](.github/workflows/pre-release-version-check.yaml)**
  - Validates version bump in `pyproject.toml` when targeting release branches
  - **Required status check**: `validate-version-bump`

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
| [installation-guide.md](docs/installation-guide.md) | One-time org setup (secrets, variables, rulesets) | Org admins |
| [usage-guide.md](docs/usage-guide.md) | How to call this orchestrator from downstream repos | Repository maintainers |
| [ORG_SETUP_GUIDE.md](docs/ORG_SETUP_GUIDE.md) | Detailed ruleset configuration and branch protection | Org admins / DevOps |
| [DEPLOYMENT_PATTERNS.md](docs/DEPLOYMENT_PATTERNS.md) | Setup patterns for private-only, private→public, public-only repos | Repository teams |
| [TESTBED.md](docs/TESTBED.md) | How to validate policy behavior before release | Release managers |

### Example Workflows and Templates

- **[docs/examples/](docs/examples/)** — Reference workflows for downstream repos (all pin to `@release`)
  - [downstream-ci-orchestrator.yaml](docs/examples/downstream-ci-orchestrator.yaml) — Universal entry point
  - [downstream-private-only-ci-orchestrator.yaml](docs/examples/downstream-private-only-ci-orchestrator.yaml) — Private-only repo
  - [downstream-private-to-public-ci-orchestrator.yaml](docs/examples/downstream-private-to-public-ci-orchestrator.yaml) — Private-to-public repo

- **[templates/](templates/)** — Copyable starter package for downstream adopters
  - [templates/setup.sh](templates/setup.sh) — Automated setup script
  - [templates/repo-variables.example.env](templates/repo-variables.example.env) — Repository variable defaults
  - [templates/org-variables.example.env](templates/org-variables.example.env) — Organization variable reference
  - [templates/README.md](templates/README.md) — Quick reference guide

---

## Architecture

### Routing Model

```
Downstream Repo Event
    ↓
workflow_call: workflow-orchestrator.yaml@release   ← Stable release tag
    ↓
  route job reads org/repo variables
    ↓
  route job evaluates event conditions
    ↓
  route outputs flags: RUN_BUILD, RUN_ENSURE_*, RUN_BACK_SYNC, RUN_SYNC_*, RUN_PUBLISH
    ↓
  conditional jobs call specific workflows
    ↓
Workflows execute with inherited secrets + config
```

### Variable Resolution

```
Downstream repo calls config.yaml with optional inputs
    ↓
  inputs provided?
    Yes → Use it
    No  → Check org variables
      Found?
        Yes → Use it
        No  → Use built-in default
```

### Configuration Scope

**Secrets** (sensitive, org-wide with per-repo access):
- `REPO_SYNC_TOKEN` — cross-repo sync
- `PYPI_TOKEN` — PyPI publishing

**Variables** (org defaults, repo overrides allowed):
- `PRIVATE_REPO`, `PUBLIC_REPO`
- Branch names (main, release, incoming)
- Python versions
- Test matrix

---

## How to Use This (Quick Start)

### 1. Development in This Repository

Workflows in this repository use **self-orchestrator** for testing:

```bash
# Edit workflows
git checkout -b feat/my-workflow-change
# Edit .github/workflows/...

# Self-orchestrator automatically tests your changes
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

### 2. Organization Admin Setup (One-Time)

```bash
# 1. Create org secrets
GitHub UI → Organization Settings → Secrets and variables → Secrets
  • Add REPO_SYNC_TOKEN (PAT with repo access)
  • Add PYPI_TOKEN (PyPI publish token)

# 2. Create org variables
GitHub UI → Organization Settings → Secrets and variables → Variables
  • Add PRIVATE_REPO, PUBLIC_REPO, branch names, version matrix
  # Template is in docs/ORG_SETUP_GUIDE.md

# 3. Configure rulesets
GitHub UI → Organization Settings → Rulesets
  # Template is in docs/ORG_SETUP_GUIDE.md
```

### 3. Per-Repository Setup (Repeatable)

**For each adopter repo**, use templates for quickest setup:

```bash
# Option A: Automatic (recommended)
bash <(curl -fsSL https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/release/templates/setup.sh) private-only

# Option B: Manual
mkdir -p .github/workflows
curl https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/release/docs/examples/downstream-ci-orchestrator.yaml \
  > .github/workflows/ci-orchestrator.yaml
git add .github/workflows/ci-orchestrator.yaml
git commit -m "feat: add centralized CI/CD orchestrator"
git push origin main

# Share access to required secrets
GitHub UI → Repository Settings → Secrets and variables
  # Grant access to REPO_SYNC_TOKEN (if using sync)
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
| Centralized routing logic | Single control plane prevents drift; easier to audit |
| Config via org variables | DRY principle; reduce duplication across repos |
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

## Next Steps (for You)

1. **Review** [ORG_SETUP_GUIDE.md](docs/ORG_SETUP_GUIDE.md) — decide on branch protection strategy
2. **Identify** first 1-2 pilot repos (private-only and/or private→public)
3. **Follow** [DEPLOYMENT_PATTERNS.md](docs/DEPLOYMENT_PATTERNS.md) for pilot setup
4. **Add entry workflow** to pilot repos
5. **Validate** using [TESTBED.md](docs/TESTBED.md) checklist
6. **Iterate** on rulesets/variables based on pilot feedback
7. **Rollout** to broader organization with staged enablement

---

## Support and Troubleshooting

- **Routing not working?** → Check [workflow-orchestrator.yaml](.github/workflows/workflow-orchestrator.yaml) branch conditions
- **Check not appearing?** → Verify PR matches routing condition; check workflow syntax
- **Merge blocked unexpectedly?** → Verify required check is passing; review [ORG_SETUP_GUIDE.md](docs/ORG_SETUP_GUIDE.md) ruleset config
- **Secret not resolving?** → Confirm secret granted to repository in org settings
- **Variable precedence confusion?** → Refer to [usage-guide.md](docs/usage-guide.md) config layer explanation

---

## Architecture Diagram

```
┌─────────────────────────────────────┐
│  Organization Configuration         │
│ (Secrets & Variables in GitHub)     │
│  - REPO_SYNC_TOKEN                  │
│  - PYPI_TOKEN                       │
│  - *_REPO, *_BRANCH configs         │
│  - TEST_MATRIX_JSON                 │
└─────────────────────────────────────┘
            ↓
┌─────────────────────────────────────┐
│  This Repository (workflows)        │
│  Central Orchestrator & Testbed     │
│ ┌─────────────────────────────────┐ │
│ │ workflow-orchestrator.yaml      │ │ ← Entry point (listens to all events)
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ config.yaml                     │ │ ← Config resolution (inputs → vars → defaults)
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
         /.github/workflows/workflow-orchestrator.yaml@main
            ↓
┌─────────────────────────────────────┐
│  Downstream Repos (many)            │
│ ┌─────────────────────────────────┐ │
│ │ .github/workflows/              │ │
│ │  ci-orchestrator.yaml           │ │ ← Single file, calls central orchestrator
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

This is your centralized CI/CD control plane.
Maintain it well; organizations depend on it.

Last updated: March 20, 2026
