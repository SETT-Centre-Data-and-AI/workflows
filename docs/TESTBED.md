# Testbed Validation Guide

This repository serves as the certification testbed for the orchestrator.

Before merging workflow changes to `main`, validate that all policy routes behave correctly via controlled test PRs.

## Quick Validation Checklist

Run these tests locally or via PR to ensure policy enforcement works:

### 1. Build and Test Route

**Trigger**: PR to `main` branch

```bash
# Create feature branch
git checkout -b test/build-and-test-route
echo "# Test" >> README.md
git add README.md
git commit -m "test: trigger build-and-test"
git push origin test/build-and-test-route

# Open PR to main via GitHub UI
# Expected: build-and-test check runs and passes
```

**Expected behavior**:
- Orchestrator routes event to `build-and-test`
- Check appears as `build-and-test` in PR checks

### 2. Private Release Source Policy (Success Case)

**Trigger**: PR to `release` _from `main`_

```bash
# Ensure the branch is based on the latest `main`
git checkout main
git pull origin main

# Create release PR from main
git checkout -b release-pr-from-main-success
echo "release: v0.2.0" >> CHANGELOG.md
git add CHANGELOG.md
git commit -m "chore: bump version"
git push origin release-pr-from-main-success

# Open PR against release branch via GitHub UI
# Expected: ensure-release-source check PASSES
```

**Expected behavior**:
- Check `ensure-release-source` appears in PR
- Check **passes** (green) because head ref is `main`

### 3. Private Release Source Policy (Failure Case)

**Trigger**: PR to `release` _from a different branch_

```bash
# Create a feature branch (not main)
git checkout -b test/invalid-release-source
echo "# Test feature" >> README.md
git add README.md
git commit -m "feat: test"
git push origin test/invalid-release-source

# Open PR against release branch via GitHub UI
# Expected: ensure-release-source check FAILS
```

**Expected behavior**:
- Check `ensure-release-source` appears in PR
- Check **fails** (red) because head ref is not `main`
- PR cannot be merged while check fails

### 4. Version Bump Check

**Trigger**: PR to `release` with version change in `pyproject.toml`

```bash
# Start from latest release branch
git checkout release
git pull origin release

# Create version-bump PR
git checkout -b test/version-bump
# Edit pyproject.toml: change version = "0.1.0" to "0.2.0"
git add pyproject.toml
git commit -m "bump: version 0.1.0 → 0.2.0"
git push origin test/version-bump

# Open PR against release branch via GitHub UI
# Expected: validate-version-bump check PASSES
```

**Expected behavior**:
- Check `validate-version-bump` appears in PR
- Check **passes** because version was bumped vs base release branch

### 5. Version Bump Check (Failure Case)

**Trigger**: PR to `release` _without_ version change

```bash
# Start from latest release branch
git checkout release
git pull origin release

# Create PR without version bump
git checkout -b test/no-version-bump
echo "# Readme edit" >> README.md
git add README.md
git commit -m "docs: update readme"
git push origin test/no-version-bump

# Open PR against release branch via GitHub UI
# Expected: validate-version-bump check FAILS
```

**Expected behavior**:
- Check `validate-version-bump` appears in PR
- Check **fails** because pyproject.toml version unchanged
- PR cannot be merged while check fails

### 6. Back-Sync and Sync-to-Public Route

**Trigger**: Merge to `main` → `release` PR → merge to `release`

**Note**: This requires both repo tokens and appropriate branch setup. Simulate via:

1. Merge PR to `main` (from step 1)
2. Create PR from `main` to `release` (from step 2)
3. Merge PR to `release`
4. Check workflow runs tab: `back-sync-release-to-main` and `sync-to-public` workflows should trigger

**Expected behavior**:
- Orchestrator detects merged PR to release with head=main
- Triggers back-sync workflow
- Triggers sync-to-public workflow

---

## Comprehensive Test Matrix

Create a test branch and open a PR that runs all scenarios:

```bash
# Create and push test branch
git checkout -b test/full-validation
git commit --allow-empty -m "test: full policy validation"
git push origin test/full-validation

# Open PR to main (tests build-and-test)
# Observe: build-and-test check
# Expected: ✓ passes

# Open PR from test/full-validation to release (tests release policy)
# Observe: ensure-release-source check
# Expected: ✗ fails (head is not main)

# Close PR, then:
# Merge test branch to main first
# Create new PR from main to release
# Observe: ensure-release-source check
# Expected: ✓ passes
```

## Policy Route Decision Tree

Use this to understand when each check should run:

```
Event: pull_request
  Repository is PRIVATE_REPO?
    Yes:
      Base branch is PRIVATE_REPO_MAIN_BRANCH?
        Yes:
          Action is opened|reopened|synchronize?
            Yes: run build-and-test
      Base branch is PRIVATE_REPO_RELEASE_BRANCH?
        Yes:
          Action is opened|reopened|synchronize?
            Yes: run ensure-release-source, validate-version-bump
          Action is closed AND merged?
            Yes: run back-sync-release-to-main, sync-to-public
  Repository is PUBLIC_REPO?
    Yes:
      Base branch is PUBLIC_REPO_RELEASE_BRANCH?
        Yes:
          Action is opened|reopened|synchronize?
            Yes: run ensure-release-source, validate-version-bump

Event: workflow_dispatch
  Repository is PRIVATE_REPO?
    Yes:
      Ref is PRIVATE_REPO_RELEASE_BRANCH?
        Yes: run back-sync-release-to-main, sync-to-public
  Repository is PUBLIC_REPO?
    Yes:
      Ref is PUBLIC_REPO_RELEASE_BRANCH?
        Yes and publish toggle enabled: run publish-to-pypi
```

## Before Releasing Workflow Changes

1. **Create a test branch** for workflow changes
2. **Run the validation checklist above** on that branch
3. **Verify all checks appear and produce expected results**
4. **Merge test branch to main only after validation passes**
5. **Tag release when validation is complete** (optional; use `@main` for immediate rollout)

## Debugging Failed Checks

### Check doesn't appear in PR

- Verify routing conditions in [workflow-orchestrator.yaml](./.github/workflows/workflow-orchestrator.yaml)
- Check PR matches a routing condition (e.g., base branch name)
- Check workflow file syntax is valid (no YAML errors)

### Check appears but fails unexpectedly

- Click "Details" on the check
- Review workflow run logs
- Trace the issue to the specific step
- Fix in the branch and push again

### Skip check temporarily for testing

Add an `if: false` condition to the workflow step in the test branch, then remove it before final release:

```yaml
- name: My Step
  if: false  # Temporarily disabled for testing
  run: echo "This step is skipped"
```

---

## Integration with CI/CD Metrics

Track policy enforcement effectiveness:

- **Check pass rate**: Percentage of PRs that pass required checks
- **Policy violations**: Count of enforced-but-failed checks (indicates user confusion or policy mismatch)
- **Release cycle time**: Time from main merge to release publish

Use GitHub API or Actions artifacts to collect metrics over time.

---

## Further Reading

- [Orchestrator source](../.github/workflows/workflow-orchestrator.yaml)
- [Config contract](../.github/workflows/config.yaml)
