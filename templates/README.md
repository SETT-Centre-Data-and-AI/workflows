# Quick Reference: Using the CI/CD Orchestrator in Your Repo

## 1. Run Setup Script (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/release/templates/setup.sh) private-only
```

Or specify repo type:
- `private-only` — Development only, no public release
- `private-public` — Private dev with public sync
- `public-only` — Public repo only

## 2. Manual Setup

Copy the appropriate workflow to your repo:

```bash
mkdir -p .github/workflows
curl https://raw.githubusercontent.com/SETT-Centre-Data-and-AI/workflows/release/docs/examples/downstream-ci-orchestrator.yaml \
  -o .github/workflows/ci-orchestrator.yaml
git add .github/workflows/ci-orchestrator.yaml
git commit -m "feat: add centralized CI/CD orchestrator"
git push origin main
```

## 3. Configure Variables

**Organization-level (one-time setup)**:
Go to organization Settings → Secrets and variables → Variables

Reference: [org-variables.example.env](org-variables.example.env)

**Repository-level (optional overrides)**:
Go to repository Settings → Secrets and variables → Variables

Reference: [repo-variables.example.env](repo-variables.example.env)

## 4. Configure Secrets

**Organization-level (one-time setup)**:
Go to organization Settings → Secrets and variables → Secrets → New organization secret

- `REPO_SYNC_TOKEN` — GitHub PAT for cross-repo sync (skip if private-only)
- `PYPI_TOKEN` — PyPI token for publishing (skip if private-only)

Then grant repository access to each secret.

## 5. Test

Open a PR to `main` → check that `build-and-test` check appears.
Open a PR to `release` from non-main → check that enforcement fails as expected.

## Frequently Asked Questions

**Q: Should I use @main or @release?**
A: Always use `@release` for stable, tested versions. Use `@main` only during development of the orchestrator itself.

**Q: Can I override org variables in my repo?**
A: Yes. Set repository variables with the same name and they take precedence.

**Q: Do I need to set up all the variables?**
A: No. Organization variables provide defaults. Only override what's unique to your repo.

**Q: What if I want to temporarily disable sync?**
A: Remove `REPO_SYNC_TOKEN` access from your repo, update PUBLIC_REPO to empty, or skip merging to release.

**Q: How do I know if it worked?**
A: Push a test PR to main and check that the build-and-test check runs. Details in [../TESTBED.md](../TESTBED.md).

## More Information

- **Full setup guide**: [../docs/ORG_SETUP_GUIDE.md](../docs/ORG_SETUP_GUIDE.md)
- **Deployment patterns**: [../docs/DEPLOYMENT_PATTERNS.md](../docs/DEPLOYMENT_PATTERNS.md)
- **Validation checklist**: [../docs/TESTBED.md](../docs/TESTBED.md)
- **Implementation overview**: [../IMPLEMENTATION_SUMMARY.md](../IMPLEMENTATION_SUMMARY.md)
