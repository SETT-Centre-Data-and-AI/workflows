# Deployment Patterns

Choose the pattern that matches the repository lifecycle and publication model.

## Pattern 1: Private-Only Repository

**Use when**: Development happens privately; no public release/publication planned (or later).

**Repos involved**: 1 (private only)

**Workflows triggered**:
- `build-and-test`: PR to main
- `ensure-release-source`: PR to release branch
- `pre-release-version-check`: PR to release branch

**No sync/publish to public repo.**

### Setup

1. Copy [orchestrator.yaml](../../repo_template/.github/workflows/orchestrator.yaml) to `.github/workflows/orchestrator.yaml`

2. Edit `.github/workflows/orchestrator.yaml` inputs:
   ```
   private-repo: your-org/your-private-repo
   package-name: your_package
   package-slug: your-package
   public-repo: ''
   ```

   Optional overrides only if needed:
   ```
   test-matrix-json: '{"include":[{"os":"ubuntu-latest","python-version":"3.13"}]}'
   ```

3. No secrets needed (no cross-repo sync).

4. Branch protection for `release`:
   - Require: `ensure-release-source`
   - Require: `pre-release-version-check`

### Example Flow

```
Feature branch → PR to main
    ↓ (check: build-and-test passes)
Merge to main

main → Create PR to release
   ↓ (check: ensure-release-source passes, pre-release-version-check passes)
Merge to release
    ↓
(end; no further sync)
```

## Pattern 2: Private→Public Sync (Mandatory)

**Use when**: Core development happens privately; public version derives from private via controlled sync.

**Repos involved**: 2 (private + public mirror)

**Workflows triggered**:
- Private main: `build-and-test`
- Private release: `ensure-release-source`, `pre-release-version-check`, `back-sync-release-to-main`, `sync-to-public`
- Public release: `ensure-release-source`, `pre-release-version-check`, `publish-to-pypi`

**Mandatory for all adopters** unless configured otherwise.

### Setup

**Private Repository**:

1. Copy [orchestrator.yaml](../../repo_template/.github/workflows/orchestrator.yaml) to `.github/workflows/orchestrator.yaml`

2. Edit `.github/workflows/orchestrator.yaml` inputs:
   ```
   private-repo: your-org/your-private-repo
   public-repo: your-org/your-public-repo
   package-name: your_package
   package-slug: your-package
   ```

   Optional overrides only if needed:
   ```
   test-matrix-json: '{"include":[{"os":"ubuntu-latest","python-version":"3.13"}]}'
   ```

3. Grant secrets:
   - `MANAGEMENT_TOKEN` (needs read/write on both repos)

4. Branch protection:
   - `main`: require `build-and-test`
   - `release`: require `ensure-release-source`, `pre-release-version-check`

**Public Repository**:

1. Copy [orchestrator.yaml](../../repo_template/.github/workflows/orchestrator.yaml) to `.github/workflows/orchestrator.yaml`

2. Edit `.github/workflows/orchestrator.yaml` inputs:
   ```
   public-repo: your-org/your-public-repo
   package-name: your_package
   package-slug: your-package
   private-repo: ''
   ```

   Optional overrides only if needed:
   ```
   test-matrix-json: '{"include":[{"os":"ubuntu-latest","python-version":"3.13"}]}'
   ```
   (Do not set PRIVATE_REPO; workflow will skip private-only checks.)

3. Grant secrets:
   - `PYPI_TOKEN` (for publishing)

4. Branch protection:
   - `release`: require `ensure-release-source`, `pre-release-version-check`, `publish-to-pypi`

### Example Flow

```
Private main PR
    ↓ (check: build-and-test passes)
Merge to private main

private main → PR to private release
   ↓ (checks: ensure-release-source, pre-release-version-check pass)
Merge to private release
    ↓ (auto)
  ├─ back-sync: create PR release→main in private repo
  └─ sync-to-public:
       ├─ Push private release to public incoming_from_private
       └─ Create PR public incoming_from_private→release

public incoming PR
   ↓ (checks: ensure-release-source, pre-release-version-check pass)
Merge to public release
    ↓ (auto)
   └─ publish-to-pypi: build and upload to PyPI (if publish-on-release/PUBLISH_ON_RELEASE is true; disabled by default, enable opt-in)
```

## Pattern 3: Public-Only Repository

**Use when**: Public repository (no private mirror); CI gates only.

**Repos involved**: 1 (public only)

**Workflows triggered**:
- `build-and-test` (if configured for public repo)
- `ensure-release-source`
- `pre-release-version-check`
- `publish-to-pypi`

### Setup

1. Copy [orchestrator.yaml](../../repo_template/.github/workflows/orchestrator.yaml) to `.github/workflows/orchestrator.yaml`

2. Edit `.github/workflows/orchestrator.yaml` inputs:
   ```
   public-repo: your-org/your-public-repo
   package-name: your_package
   package-slug: your-package
   private-repo: ''
   ```

   Optional overrides only if needed:
   ```
   test-matrix-json: '{"include":[{"os":"ubuntu-latest","python-version":"3.13"}]}'
   ```

3. Grant secrets:
   - `PYPI_TOKEN`

4. Branch protection:
   - `release`: require `ensure-release-source`, `pre-release-version-check`, `publish-to-pypi`

### Note

This pattern bypasses the private-to-public sync workflow. Use only when no private version exists.

## Choosing A Pattern

| Pattern | Private Repo | Public Repo | Sync | Publishing | Use Case |
|---------|:---:|:---:|:---:|:---:|----------|
| 1. Private-only | ✓ | — | — | — | Internal tools; no public release |
| 2. Private→Public | ✓ | ✓ | ✓ | ✓ | Open-source with private dev; controlled release |
| 3. Public-only | — | ✓ | — | ✓ | Public projects; no parallel private development |

## Migration Path

**Starting with Pattern 1 → Pattern 2**:

1. Create a public repository (e.g., `your-org/your-package`)
2. In private repo `orchestrator.yaml`, set `public-repo: your-org/your-package`
3. Seed public repo with initial commit
4. Grant `MANAGEMENT_TOKEN` in org secrets
5. Trigger manual `back-sync` and `sync-to-public` workflows
6. Add entry workflow to public repo
7. Test full sync flow before merging to private release

**Temporarily Disabling Pattern 2 → Pattern 1**:

1. In private repo, set `public-repo: ''` in the caller workflow
2. Orchestrator will skip `sync-to-public` steps automatically
3. Restore `public-repo` input when ready to resume

## Caller Workflow Overrides

If a downstream repo needs custom behavior, set overrides in `.github/workflows/orchestrator.yaml`:

```
# Example: Custom branch names
private-repo-main-branch: develop
private-repo-release-branch: stable

# Required package naming
package-name: your_package
package-slug: your-package

# Example: Custom matrix inline JSON
test-matrix-json: '{"include":[{"os":"ubuntu-latest","python-version":"3.12"}]}'
```

Workflow inputs take precedence over built-in defaults.

## Troubleshooting Deployment Patterns

### "Why isn't sync-to-public running?"

- Confirm `public-repo` input is set in `orchestrator.yaml`
- Check `MANAGEMENT_TOKEN` is granted to both repos
- Verify merge was to private release (not another branch)

### "How do I skip sync for a single release?"

- Temporarily remove `MANAGEMENT_TOKEN` access
- Or pin private repo to a tag version that does not call sync (advanced)

### "Can I have multiple public repos?"

- Current design: 1 private → 1 public
- For multiple public targets: manually sync or request custom workflow

## Further Reading

- [Organisation Setup Guide](ORG_SETUP_GUIDE.md)
- [Usage and Integration](usage-guide.md)
