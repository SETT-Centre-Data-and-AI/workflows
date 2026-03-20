# Organisation Setup Guide

Configure your GitHub organisation to enforce centralised CI/CD policy using these workflows.

## Overview

This guide shows you how to:
1. Create organisation-level secrets and variables
2. Configure required status checks via GitHub rulesets
3. Apply branch protection rules across adopter repositories
4. Define which repos participate in the mandatory private-to-public sync pipeline

## 1. Organisation Secrets Setup

Create these organisation secrets with **selected repository access** (grant access only to repos that need them):

### REPO_SYNC_TOKEN
- **Purpose**: GitHub Personal Access Token for cross-repo sync operations (back-sync, sync-to-public, sync-from-public)
- **Scope**: Read/write access to both private and public repositories
- **Minimum permissions**:
  - `repo` (full control of private repositories)
  - `public_repo` (public repository read/write)
  - `workflow` (update workflows)
- **Apply to**: All repositories using `sync-to-public` or `back-sync-release-to-main` workflows

### PYPI_TOKEN
- **Purpose**: PyPI publish-only API token
- **Scope**: Publish only (not download/manage)
- **Apply to**: Public repositories with `publish-to-pypi` workflows

## 2. Organisation Variables Setup

Create these organisation variables with appropriate defaults. Downstream repositories can override via repository variables.

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `PRIVATE_REPO` | `workflows_development` | Full repo path of private repository (e.g., `org/repo-private`) |
| `PRIVATE_REPO_MAIN_BRANCH` | `main` | Main development branch in private repo |
| `PRIVATE_REPO_RELEASE_BRANCH` | `release` | Release branch in private repo |
| `PRIVATE_REPO_INCOMING_BRANCH` | `incoming_from_public` | Sync target for public updates |
| `PUBLIC_REPO` | `workflows` | Full repo path of public repository (e.g., `org/repo`) |
| `PUBLIC_REPO_INCOMING_BRANCH` | `incoming_from_private` | Sync target for private release updates |
| `PUBLIC_REPO_RELEASE_BRANCH` | `release` | Release branch in public repo |
| `RELEASE_CHECK_REPOS_JSON` | `["workflows_development","workflows"]` | JSON array of repos that require version bump on release PRs |
| `BUILD_SMOKE_PYTHON_VERSION` | `3.13` | Python version for quick smoke test |
| `TEST_MATRIX_JSON` | `[{"os":"ubuntu-latest","python-version":"3.11"},...]` | Full test matrix JSON |
| `VERSION_CHECK_PYTHON_VERSION` | `3.12` | Python version for running version check script |
| `PUBLISH_PYTHON_VERSION` | `3.13` | Python version for building and publishing |

### Setting Up Organisation Variables in GitHub

1. Go to **Organisation Settings** → **Secrets and variables** → **Variables**.
2. Click **New organisation variable** for each variable above.
3. Paste values exactly as shown.
4. Leave **Access** as **All repositories** (downstream repos can override if needed).

## 3. Required Status Checks Configuration

### Check Names Produced by Orchestrator

Your orchestrator produces these check contexts. When _required_, they prevent merge until passing:

| Check Name | Workflow | Condition |
|------------|----------|-----------|
| `build-and-test` | [build-and-test.yaml](./../.github/workflows/build-and-test.yaml) | Private PR to main |
| `enforce-private-release-source` | [ensure-private-release-from-main.yaml](./../.github/workflows/ensure-private-release-from-main.yaml) | Private PR to release |
| `enforce-public-release-source` | [ensure-public-release-from-incoming.yaml](./../.github/workflows/ensure-public-release-from-incoming.yaml) | Public PR to release |
| `validate-version-bump` | [pre-release-version-check.yaml](./../.github/workflows/pre-release-version-check.yaml) | Any PR to release branch in version-check repos |
| `back-sync-release-to-main` | [back-sync-release-to-main.yaml](./../.github/workflows/back-sync-release-to-main.yaml) | Merge to private release from main |
| `sync-to-public` | [sync-to-public.yaml](./../.github/workflows/sync-to-public.yaml) | Merge to private release from main |
| `publish-to-pypi` | [publish-to-pypi.yaml](./../.github/workflows/publish-to-pypi.yaml) | Merge to public release from incoming |

### Branch Protection Rules via GitHub Rulesets

#### For Private Repositories

Create a ruleset named `Enforce CI/CD Policy (Private)` matching branch `main`:

```
Ruleset name: Enforce CI/CD Policy (Private)
Enforcement: Active
Target branches: main
Target: Regular expression: ^main$

Required status checks:
  ✓ build-and-test

Require code reviews: 1
Dismiss stale pull request approvals: true
Require branch to be up to date before merging: true
Require conversation resolution before merging: true
Require commits to be signed: false (optional)
```

Create a ruleset named `Release Gate (Private)` matching branch `release`:

```
Ruleset name: Release Gate (Private)
Enforcement: Active
Target branches: release
Target: Regular expression: ^release$

Required status checks:
  ✓ enforce-private-release-source
  ✓ validate-version-bump

Require code reviews: 1
Dismiss stale pull request approvals: true
Require branch to be up to date before merging: true
Require conversation resolution before merging: true
```

#### For Public Repositories

Create a ruleset named `Release Gate (Public)` matching branch `release`:

```
Ruleset name: Release Gate (Public)
Enforcement: Active
Target branches: release
Target: Regular expression: ^release$

Required status checks:
  ✓ enforce-public-release-source
  ✓ validate-version-bump
  ✓ publish-to-pypi (optional, but recommended)

Require code reviews: 1 (or more)
Dismiss stale pull request approvals: true
Require branch to be up to date before merging: true
Require conversation resolution before merging: true
```

### Via GitHub API (for Terraform or Automation)

If using GitHub Terraform provider or API automation, required status checks can be enforced at org level:

```hcl
resource "github_organisation_ruleset" "private_ci" {
  name        = "Enforce CI/CD Policy (Private)"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      pattern = "^main$"
    }
  }

  rules {
    required_status_checks {
      required_check {
        context = "build-and-test"
      }
    }
    required_pull_request_reviews {
      required_approving_review_count = 1
      dismiss_stale_reviews           = true
      require_code_owner_reviews      = false
    }
    require_up_to_date_branches = true
  }
}
```

## 4. Downstream Repository Configuration

Each downstream repository adopting this orchestrator needs:

### Minimal Setup

1. **Add entry workflow**: Copy [docs/examples/downstream-ci-orchestrator.yaml](examples/downstream-ci-orchestrator.yaml) to `.github/workflows/ci-orchestrator.yaml`

2. **Set repository variables** (optional, for overrides):
   - `PRIVATE_REPO` — if different from org default
   - `PUBLIC_REPO` — if different from org default
   - Any matrix overrides

3. **Enable secret access**:
   - Grant `REPO_SYNC_TOKEN` access if repo uses back-sync or sync-to-public
   - Grant `PYPI_TOKEN` access if repo publishes to PyPI

### Example: New Private Repository

```bash
# 1. Copy entry workflow
mkdir -p .github/workflows
curl https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/main/docs/examples/downstream-ci-orchestrator.yaml \
  > .github/workflows/ci-orchestrator.yaml

# 2. Commit and push
git add .github/workflows/ci-orchestrator.yaml
git commit -m "feat: add centralised CI/CD orchestrator"
git push origin main

# 3. Grant secrets (in GitHub UI)
# Organisation Settings → Secrets and variables → Actions
# REPO_SYNC_TOKEN → Check this repository

# 4. Protect branches (if not org-wide ruleset)
# Repository Settings → Branch protection rules
```

### Example: New Public Repository

Same as private, plus:
1. Grant `PYPI_TOKEN` access in org secrets
2. Configure PyPI project classifiers in `pyproject.toml` if needed

## 5. Validation Checklist

Before rolling out across your organisation:

- [ ] Org secrets created: `REPO_SYNC_TOKEN`, `PYPI_TOKEN`
- [ ] Org variables created: `PRIVATE_REPO`, `PUBLIC_REPO`, matrix config, etc.
- [ ] Rulesets configured in at least one pilot repository
- [ ] Pilot repo has entry workflow calling `SETT-Centre-Data-and-AI/workflows/.github/workflows/workflow-orchestrator.yaml@main`
- [ ] Manual test: PR to pilot repo main → build-and-test check runs
- [ ] Manual test: PR to pilot repo release from non-main → enforce-private-release-source check fails
- [ ] Manual test: PR to pilot repo release from main → enforce-private-release-source check passes
- [ ] Manual test: Merge to main → back-sync and sync-to-public workflows triggered (if configured)

## 6. Monitoring and Troubleshooting

### Check Status Contexts Not Appearing

**Symptom**: Ruleset requires a check, but it doesn't appear in PR.

**Cause**: Routing logic determined check should not run. Review [workflow-orchestrator.yaml](../github/workflows/workflow-orchestrator.yaml) conditions.

**Fix**: Verify PR matches conditions (e.g., PR to main for build-and-test, PR to release for release checks).

### Secrets Not Resolving

**Symptom**: Workflow fails with "SECRET_NAME is not set or empty".

**Cause**: Secret not granted to this repository, or organisation doesn't have secret.

**Fix**:
1. Org Settings → Secrets and variables → Secrets
2. Check secret exists
3. Edit secret → Selected repositories → add your repo

### Rollback Strategy

If a workflow change breaks pipelines:

1. Temporarily pin downstream repos to known-good tag (e.g., `@v0.1.0`)
2. Fix issue in this repo on a branch
3. Test locally or in this repo first
4. Tag and release fixed version
5. Update downstream repos back to `@main` or new tag

## Further Reading

- [Installation and setup](installation-guide.md)
- [Usage and integration](usage-guide.md)
- [Orchestrator source](../github/workflows/workflow-orchestrator.yaml)
