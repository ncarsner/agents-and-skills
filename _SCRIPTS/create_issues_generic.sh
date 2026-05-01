#!/usr/bin/env bash
# Generic Issue Creation Script
# Prerequisites: gh CLI installed and authenticated (gh auth login)
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed or not in PATH."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: GitHub CLI is not authenticated. Run 'gh auth login' first."
  exit 1
fi

# Configuration
REPO="${1:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"
ISSUES_FILE="issues.txt" # Format: Title | Body (one per line)

if [ -z "$REPO" ]; then
  echo "Error: Unable to determine repository. Pass it as the first argument or run this script from within a GitHub repository."
  exit 1
fi

if [ ! -f "$ISSUES_FILE" ]; then
  echo "Error: $ISSUES_FILE not found. Create it with 'Title | Body' format."
  exit 1
fi

echo "Creating issues in $REPO..."

while IFS='|' read -r title body; do
  if [[ -n "$title" && -n "$body" ]]; then
    echo "Creating issue: $title"
    gh issue create --repo "$REPO" \
      --title "$(echo "$title" | xargs)" \
      --body "$(echo "$body" | xargs)"
  fi
done < "$ISSUES_FILE"

echo "Done."
