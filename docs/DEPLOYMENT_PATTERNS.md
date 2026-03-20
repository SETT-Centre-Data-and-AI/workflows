# Deployment Patterns

Choose the pattern that matches your repository's lifecycle and publication model.

## Pattern 1: Private-Only Repository

**Use when**: Development happens privately; no public release/publication planned (or later).

**Repos involved**: 1 (private only)

**Workflows triggered**:
- `build-and-test`: PR to main
- `ensure-private-release-from-main`: PR to release branch
- `validate-version-bump`: PR to release branch

**No sync/publish to public repo.**

### Setup

1. Copy [downstream-private-only-ci-orchestrator.yaml](examples/downstream-private-only-ci-orchestrator.yaml) to `.github/workflows/ci-orchestrator.yaml`

2. Set organization or repository variables:
   ```
   PRIVATE_REPO=your-org/your-private-repo
   PRIVATE_REPO_MAIN_BRANCH=main
   PRIVATE_REPO_RELEASE_BRANCH=release
   ```

3. No secrets needed (no cross-repo sync).

4. Branch protection for `release`:
   - Require: `enforce-private-release-source`
   - Require: `validate-version-bump`

### Example Flow

```
Feature branch → PR to main
    ↓ (check: build-and-test passes)
Merge to main

main → Create PR to release
    ↓ (check: enforce-private-release-source passes, validate-version-bump passes)
Merge to release
    ↓
(end; no further sync)
```

## Pattern 2: Private→Public Sync (Mandatory)

**Use when**: Core development happens privately; public version derives from private via controlled sync.

**Repos involved**: 2 (private + public mirror)

**Workflows triggered**:
- Private main: `build-and-test`
- Private release: `ensure-private-release-from-main`, `validate-version-bump`, `back-sync-release-to-main`, `sync-to-public`
- Public release: `ensure-public-release-from-incoming`, `validate-version-bump`, `publish-to-pypi`

**Mandatory for all adopters** unless configured otherwise.

### Setup

**Private Repository**:

1. Copy [downstream-private-to-public-ci-orchestrator.yaml](examples/downstream-private-to-public-ci-orchestrator.yaml) to `.github/workflows/ci-orchestrator.yaml`

2. Set variables:
   ```
   PRIVATE_REPO=your-org/your-private-repo
   PUBLIC_REPO=your-org/your-public-repo
   PRIVATE_REPO_MAIN_BRANCH=main
   PRIVATE_REPO_RELEASE_BRANCH=release
   PUBLIC_REPO_INCOMING_BRANCH=incoming_from_private
   PUBLIC_REPO_RELEASE_BRANCH=release
   ```

3. Grant secrets:
   - `REPO_SYNC_TOKEN` (needs read/write on both repos)

4. Branch protection:
   - `main`: require `build-and-test`
   - `release`: require `enforce-private-release-source`, `validate-version-bump`

**Public Repository**:

1. Copy [downstream-ci-orchestrator.yaml](examples/downstream-ci-orchestrator.yaml) to `.github/workflows/ci-orchestrator.yaml`

2. Set variables:
   ```
   PUBLIC_REPO=your-org/your-public-repo
   PUBLIC_REPO_INCOMING_BRANCH=incoming_from_private
   PUBLIC_REPO_RELEASE_BRANCH=release
   RELEASE_CHECK_REPOS_JSON=["your-org/your-public-repo"]
   ```
   (Do not set PRIVATE_REPO; workflow will skip private-only checks.)

3. Grant secrets:
   - `PYPI_TOKEN` (for publishing)

4. Branch protection:
   - `release`: require `ensure-public-release-from-incoming`, `validate-version-bump`, `publish-to-pypi`

### Example Flow

```
Private main PR
    ↓ (check: build-and-test passes)
Merge to private main

private main → PR to private release
    ↓ (checks: enforce-private-release-source, validate-version-bump pass)
Merge to private release
    ↓ (auto)
  ├─ back-sync: create PR release→main in private repo
  └─ sync-to-public:
       ├─ Push private release to public incoming_from_private
       └─ Create PR public incoming_from_private→release

public incoming PR
    ↓ (checks: ensure-public-release-from-incoming, validate-version-bump pass)
Merge to public release
    ↓ (auto)
  └─ publish-to-pypi: build and upload to PyPI
```

## Pattern 3: Public-Only Repository

**Use when**: Public repository (no private mirror); CI gates only.

**Repos involved**: 1 (public only)

**Workflows triggered**:
- `build-and-test` (if configured for public repo)
- `ensure-public-release-from-incoming`
- `validate-version-bump`
- `publish-to-pypi`

### Setup

1. Copy [downstream-ci-orchestrator.yaml](examples/downstream-ci-orchestrator.yaml) to `.github/workflows/ci-orchestrator.yaml`

2. Set variables:
   ```
   PUBLIC_REPO=your-org/your-public-repo
   PUBLIC_REPO_RELEASE_BRANCH=release
   RELEASE_CHECK_REPOS_JSON=["your-org/your-public-repo"]
   ```

3. Grant secrets:
   - `PYPI_TOKEN`

4. Branch protection:
   - `release`: require `ensure-public-release-from-incoming`, `validate-version-bump`, `publish-to-pypi`

### Note

This pattern bypasses the private-to-public sync workflow. Use only if you have no private version.

## Choosing Your Pattern

| Pattern | Private Repo | Public Repo | Sync | Publishing | Use Case |
|---------|:---:|:---:|:---:|:---:|----------|
| 1. Private-only | ✓ | — | — | — | Internal tools; no public release |
| 2. Private→Public | ✓ | ✓ | ✓ | ✓ | Open-source with private dev; controlled release |
| 3. Public-only | — | ✓ | — | ✓ | Public projects; no parallel private development |

## Migration Path

**Starting with Pattern 1 → Pattern 2**:

1. Create a public repository (e.g., `your-org/your-package`)
2. In private repo config, set `PUBLIC_REPO=your-org/your-package`
3. Seed public repo with initial commit
4. Grant `REPO_SYNC_TOKEN` in org secrets
5. Trigger manual `back-sync` and `sync-to-public` workflows
6. Add entry workflow to public repo
7. Test full sync flow before merging to private release

**Temporarily Disabling Pattern 2 → Pattern 1**:

1. In private repo, comment out `PUBLIC_REPO` variable (or set to empty)
2. Orchestrator will skip `sync-to-public` steps automatically
3. Restore variable when ready to resume

## Repository-Level Variable Overrides

If a downstream repo needs to deviate from org defaults, set repo-level variables:

**GitHub UI**: Repository Settings → Secrets and variables → Variables

```
# Example: Custom branch names
PRIVATE_REPO_MAIN_BRANCH=develop
PRIVATE_REPO_RELEASE_BRANCH=stable
```

**Via API**:
```bash
gh variable set PRIVATE_REPO_MAIN_BRANCH -b develop -R your-org/your-repo
```

Override values take precedence over org defaults.

## Troubleshooting Deployment Patterns

### "Why isn't sync-to-public running?"

- Confirm `PUBLIC_REPO` variable is set
- Check `REPO_SYNC_TOKEN` is granted to both repos
- Verify merge was to private release (not another branch)

### "How do I skip sync for a single release?"

- Temporarily remove `REPO_SYNC_TOKEN` access
- Or pin private repo to a tag version that does not call sync (advanced)

### "Can I have multiple public repos?"

- Current design: 1 private → 1 public
- For multiple public targets: manually sync or request custom workflow

## Further Reading

- [Organization Setup Guide](ORG_SETUP_GUIDE.md)
- [Usage and Integration](usage-guide.md)
