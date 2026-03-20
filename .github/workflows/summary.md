# Workflow Summary

This folder uses an orchestrator model:
- [workflow-orchestrator.yaml](workflow-orchestrator.yaml) is the entry workflow for PR events.
- Most other workflows are reusable targets (`workflow_call`) run by the orchestrator.
- [config.yaml](config.yaml) is the shared source of repository, branch, and runtime settings.

## Event Flow Quick Reference
- Private PR opened/reopened/synchronize to `main`:
	- Orchestrator runs `build-and-test`.
- Private PR opened/reopened/synchronize to `release`:
	- Orchestrator runs `ensure-private-release-from-main` and `pre-release-version-check`.
- Private PR merged to `release` with head `main`:
	- Orchestrator runs `back-sync-release-to-main` and `sync-to-public`.
- Public PR opened/reopened/synchronize to `release`:
	- Orchestrator runs `ensure-public-release-from-incoming` and `pre-release-version-check`.
- Public PR merged to `release` with head `incoming_from_private`:
	- Orchestrator runs `publish-to-pypi`.
- Manual dispatch on private `release`:
	- Orchestrator runs `back-sync-release-to-main` and `sync-to-public`.
- Manual dispatch on public `release`:
	- Orchestrator runs `publish-to-pypi`.
- Manual dispatch of `sync-from-public`:
	- Runs independently (not run by orchestrator).

## Operations Table

| Workflow | Runs When | Skips When | Pass Means | Fails When |
|---|---|---|---|---|
| [config.yaml](config.yaml) | Any workflow calls it (`workflow_call`) | Never | All expected outputs are available to caller jobs | Reusable workflow execution error |
| [workflow-orchestrator.yaml](workflow-orchestrator.yaml) | Any PR lifecycle event (`opened`, `reopened`, `synchronize`, `closed`) or manual dispatch | Individual downstream jobs are skipped when route flags are `false` | Correct downstream workflows are selected and dispatched for current context | Route script/dispatch job fails |
| [build-and-test.yaml](build-and-test.yaml) | Called by orchestrator for private PRs to private main | Repo is not configured private repo | Package builds and smoke + test matrix complete successfully | Build, install, or test command fails |
| [ensure-private-release-from-main.yaml](ensure-private-release-from-main.yaml) | Called by orchestrator for private PRs to private release | Repo is not private repo, or PR base is not private release | PR head branch equals configured private main | PR head branch is not configured private main |
| [ensure-public-release-from-incoming.yaml](ensure-public-release-from-incoming.yaml) | Called by orchestrator for public PRs to public release | Repo is not public repo, or PR base is not public release | PR head branch equals configured public incoming branch | PR head branch is not configured public incoming branch |
| [pre-release-version-check.yaml](pre-release-version-check.yaml) | Called by orchestrator for release PR events in allowed repos | Repo is not listed in `RELEASE_CHECK_REPOS_JSON` | `pyproject.toml` version differs from base release version | Version is unchanged, or pyproject read/parse fails |
| [back-sync-release-to-main.yaml](back-sync-release-to-main.yaml) | Called by orchestrator after qualifying private release merge, or manual dispatch on private release | Repo is not private repo, or manual dispatch is not on private release | Back-sync PR is created/reused and auto-merge enabled | Token missing, mergeability unresolved/conflicting, or auto-merge cannot be enabled |
| [sync-to-public.yaml](sync-to-public.yaml) | Called by orchestrator after qualifying private release merge, or manual dispatch on private release | Repo is not private repo, or manual dispatch is not on private release | Public incoming branch is updated and PR to public release exists/reused | Token missing, git/gh command fails |
| [publish-to-pypi.yaml](publish-to-pypi.yaml) | Called by orchestrator after qualifying public release merge, or manual dispatch on public release | Repo is not public repo, or manual dispatch is not on public release | Distributions build, validate, smoke import, and upload to PyPI | Missing token, build/check/import/upload failure |
| [sync-from-public.yaml](sync-from-public.yaml) | Manual dispatch in private repo with `public_branch` input | Repo is not private repo | Selected public branch is mirrored to private incoming and PR to private main exists/reused | Token missing, input empty, or git/gh command fails |

## [config.yaml](config.yaml)
Purpose: Shared environment/config outputs for all workflows.
Trigger: `workflow_call` only.
Runs when: Any workflow calls it with `uses: ./.github/workflows/config.yaml`.
Skips when: Never (no conditional skip logic).

## [workflow-orchestrator.yaml](workflow-orchestrator.yaml)
Purpose: Decide which workflows should run for each event and dispatch them.
Trigger: `pull_request` (`opened`, `reopened`, `synchronize`, `closed`) on any base branch; `workflow_dispatch`.
Runs when: Any PR lifecycle event occurs in a repo containing this workflow, or manual run.
Skips when: Routing output for a specific downstream workflow is `false`.

Dispatch map from this workflow:
- Private PR to `main` (opened/reopened/synchronize): runs build and test.
- Private PR to `release` (opened/reopened/synchronize): runs private source-branch policy + version bump check.
- Private PR merge to `release` with head `main`: runs back-sync and sync-to-public.
- Public PR to `release` (opened/reopened/synchronize): runs public source-branch policy + version bump check.
- Public PR merge to `release` with head `incoming_from_private`: runs PyPI publish.
- Manual run on private `release`: runs back-sync and sync-to-public.
- Manual run on public `release`: runs publish-to-pypi.

## [build-and-test.yaml](build-and-test.yaml)
Purpose: Build package and run smoke + test matrix.
Trigger: `workflow_call` only.
Runs when: Called by dispatcher for private PRs targeting private main.
Skips when: Current repository is not configured private repo.

## [ensure-private-release-from-main.yaml](ensure-private-release-from-main.yaml)
Purpose: Enforce private release PR source branch policy.
Trigger: `workflow_call` only.
Runs when: Called by dispatcher for private PRs targeting private release.
Skips when: Repo is not private repo, or PR base is not private release branch.
Fails when: PR head branch is not configured private main branch.

## [ensure-public-release-from-incoming.yaml](ensure-public-release-from-incoming.yaml)
Purpose: Enforce public release PR source branch policy.
Trigger: `workflow_call` only.
Runs when: Called by dispatcher for public PRs targeting public release.
Skips when: Repo is not public repo, or PR base is not public release branch.
Fails when: PR head branch is not configured public incoming branch.

## [pre-release-version-check.yaml](pre-release-version-check.yaml)
Purpose: Ensure version is bumped for release PRs.
Trigger: `workflow_call` only.
Runs when: Called by dispatcher for release PR activity in allowed repos.
Skips when: Current repo is not listed in `RELEASE_CHECK_REPOS_JSON` from config.
Fails when: `pyproject.toml` version in PR head equals base release version.

## [back-sync-release-to-main.yaml](back-sync-release-to-main.yaml)
Purpose: Keep private `release` and `main` synchronized by creating/reusing release -> main PR and enabling auto-merge.
Trigger: `workflow_call` or `workflow_dispatch`.
Runs when: Called by dispatcher, or manually run on private release branch.
Skips when: Repo is not private repo, or manual run is not on private release branch.
No-op when: Release is not ahead of main (`ahead_by == 0`).
Fails when: Mergeability cannot be resolved, PR is conflicting, or auto-merge cannot be enabled.

## [sync-to-public.yaml](sync-to-public.yaml)
Purpose: Mirror private release into public incoming branch and create/reuse PR into public release.
Trigger: `workflow_call` or `workflow_dispatch`.
Runs when: Called by dispatcher, or manually run on private release branch.
Skips when: Repo is not private repo, or manual run is not on private release branch.
No-op when: Open public PR from incoming to release already exists.
Fails when: Repo sync token is missing.

## [publish-to-pypi.yaml](publish-to-pypi.yaml)
Purpose: Build and publish package to PyPI from public repo.
Trigger: `workflow_call` or `workflow_dispatch`.
Runs when: Called by dispatcher, or manually run on public release branch.
Skips when: Repo is not public repo, or manual run is not on public release branch.
Fails when: `PYPI_TOKEN` is missing, build/check fails, or upload fails.

## [sync-from-public.yaml](sync-from-public.yaml)
Purpose: Manual pull of selected public branch into private incoming branch, then PR to private main.
Trigger: `workflow_dispatch` only (input `public_branch` required).
Runs when: Manually dispatched in private repo.
Skips when: Current repo is not private repo.
Fails when: Sync token is missing or input branch is empty.
No-op when: Matching open PR already exists (reuses existing PR).
