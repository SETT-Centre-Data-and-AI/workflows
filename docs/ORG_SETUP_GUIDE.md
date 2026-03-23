# Organisation Setup Guide

Configure the GitHub organisation to enforce centralised CI/CD policy using these workflows.

## Overview

This guide covers:
1. Create organisation-level secrets
2. Configure required status checks via GitHub rulesets
3. Apply branch protection rules across adopter repositories
4. Define which repos participate in the mandatory private-to-public sync pipeline

## 1. Organisation Secrets Setup

Create these organisation secrets with **selected repository access** (grant access only to repos that need them):

### MANAGEMENT_TOKEN
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

## 2. Non-Secret Configuration Model

Non-secret configuration is declared in each downstream repository's `.github/workflows/ci-orchestrator.yaml` using `with:` inputs.

Required per repo:
- `package-name`
- `package-slug`
- `private-repo` and/or `public-repo`

Optional per repo:
- branch overrides
- runtime version overrides
- `test-matrix-json` inline matrix override
- `publish-on-release` toggle (`true`/`false`)

Optional repo variable fallback:
- `PUBLISH_ON_RELEASE=true|false`

This keeps behavior visible in code and removes dependency on GitHub variables for normal operation.

## 3. Required Status Checks Configuration

### Check Names Produced by Orchestrator

The orchestrator produces these check contexts. When _required_, they prevent merge until passing:

| Check Name | Workflow | Condition |
|------------|----------|-----------|
| `build-and-test` | [build-and-test.yaml](./../.github/workflows/build-and-test.yaml) | Private PR to main |
| `ensure-release-source` | [ensure-release-source.yaml](./../.github/workflows/ensure-release-source.yaml) | PR to private or public release branch |
| `validate-version-bump` | [pre-release-version-check.yaml](./../.github/workflows/pre-release-version-check.yaml) | Any PR to private/public release branch |
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
  ✓ ensure-release-source
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
  ✓ ensure-release-source
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

2. **Set caller workflow inputs**:
  - Configure `.github/workflows/ci-orchestrator.yaml` `with:` inputs
  - Set required package/repo identity values
  - Add optional `test-matrix-json` only if custom matrix is needed

3. **Enable secret access**:
   - Grant `MANAGEMENT_TOKEN` access if repo uses back-sync or sync-to-public
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
# MANAGEMENT_TOKEN → Check this repository

# 4. Protect branches (if not org-wide ruleset)
# Repository Settings → Branch protection rules
```

### Example: New Public Repository

Same as private, plus:
1. Grant `PYPI_TOKEN` access in org secrets
2. Configure PyPI project classifiers in `pyproject.toml` if needed

## 5. Validation Checklist

Before rolling out across the organisation:

- [ ] Org secrets created: `MANAGEMENT_TOKEN`, `PYPI_TOKEN`
- [ ] Pilot repo workflow has required `with:` inputs set in `ci-orchestrator.yaml`
- [ ] Rulesets configured in at least one pilot repository
- [ ] Pilot repo has entry workflow calling `SETT-Centre-Data-and-AI/workflows/.github/workflows/workflow-orchestrator.yaml@main`
- [ ] Manual test: PR to pilot repo main → build-and-test check runs
- [ ] Manual test: PR to pilot repo release from non-main → ensure-release-source check fails
- [ ] Manual test: PR to pilot repo release from main → ensure-release-source check passes
- [ ] Manual test: Merge to main → back-sync and sync-to-public workflows triggered (if configured)

## 6. Monitoring and Troubleshooting

### Check Status Contexts Not Appearing

**Symptom**: Ruleset requires a check, but it doesn't appear in PR.

**Cause**: Routing logic determined that the check should not run. Review [workflow-orchestrator.yaml](../.github/workflows/workflow-orchestrator.yaml) conditions.

**Fix**: Verify PR matches conditions (e.g., PR to main for build-and-test, PR to release for release checks).

### Secrets Not Resolving

**Symptom**: Workflow fails with "SECRET_NAME is not set or empty".

**Cause**: Secret not granted to this repository, or organisation doesn't have secret.

**Fix**:
1. Org Settings → Secrets and variables → Secrets
2. Check secret exists
3. Edit secret → Selected repositories → add the repository

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
- [Orchestrator source](../.github/workflows/workflow-orchestrator.yaml)
