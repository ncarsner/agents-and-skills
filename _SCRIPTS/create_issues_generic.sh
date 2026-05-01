#!/usr/bin/env bash
# Generic Issue Creation Script
# Prerequisites: gh CLI installed and authenticated (gh auth login)
set -e

# Configuration
REPO="your-org/your-repo"
ISSUES_FILE="issues.txt" # Format: Title | Body (one per line)

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
