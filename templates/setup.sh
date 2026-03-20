#!/bin/bash
# Downstream repository setup script
# Run this in your target repository to initialize CI/CD orchestrator

set -e

REPO_TYPE="${1:-private-only}"  # Options: private-only, private-public, public-only
WORKFLOWS_REPO="SETT-Centre-Data-and-AI/workflows"
WORKFLOWS_REF="release"

echo "Setting up $REPO_TYPE CI/CD orchestrator from $WORKFLOWS_REPO@$WORKFLOWS_REF"

# Create .github/workflows directory
mkdir -p .github/workflows

# Select and copy appropriate orchestrator workflow
case "$REPO_TYPE" in
  private-only)
    EXAMPLE_FILE="downstream-private-only-ci-orchestrator.yaml"
    ;;
  private-public)
    EXAMPLE_FILE="downstream-private-to-public-ci-orchestrator.yaml"
    ;;
  public-only)
    EXAMPLE_FILE="downstream-ci-orchestrator.yaml"
    ;;
  *)
    echo "Unknown repo type: $REPO_TYPE"
    echo "Use: private-only, private-public, or public-only"
    exit 1
    ;;
esac

echo "Downloading $EXAMPLE_FILE..."
curl -fsSL \
  "https://raw.githubusercontent.com/$WORKFLOWS_REPO/$WORKFLOWS_REF/docs/examples/$EXAMPLE_FILE" \
  -o .github/workflows/ci-orchestrator.yaml

echo "✓ Workflow added: .github/workflows/ci-orchestrator.yaml"

# Copy repository variables template
echo "Creating repository variables template..."
cp -v "$(dirname "$0")/repo-variables.example.env" .github/repo-variables.example.env 2>/dev/null || \
  echo "Note: repo-variables.example.env not found locally (OK if running from remote)"

echo ""
echo "Setup complete! Next steps:"
echo ""
echo "1. Review and test:"
echo "   git add .github/workflows/ci-orchestrator.yaml"
echo "   git commit -m 'feat: add centralized CI/CD orchestrator'"
echo "   git push origin HEAD"
echo ""
echo "2. Go to GitHub and open a PR"
echo "   Expected: CI orchestrator runs and triggers policy checks"
echo ""
echo "3. Configure organization secrets (one-time per org):"
echo "   - REPO_SYNC_TOKEN (if using back-sync or sync-to-public)"
echo "   - PYPI_TOKEN (if publishing to PyPI)"
echo ""
echo "4. Set organization variables (one-time per org):"
echo "   - PRIVATE_REPO, PUBLIC_REPO, branch names, etc."
echo "   See: https://github.com/$WORKFLOWS_REPO/blob/release/docs/ORG_SETUP_GUIDE.md"
echo ""
echo "5. Grant repository access to secrets (per repo):"
echo "   - In org GitHub settings, grant this repo access to needed secrets"
echo ""
echo "For detailed instructions, see:"
echo "   https://github.com/$WORKFLOWS_REPO/blob/release/docs/DEPLOYMENT_PATTERNS.md"
