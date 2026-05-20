# Skill: Secret Scanning & Pre-commit Hooks

Mandatory pre-commit setup for all projects derived from these templates.
No project may accept contributions without these hooks installed and passing.

---

## Quick Reference

```bash
uv add --dev pre-commit detect-secrets
pre-commit install
detect-secrets scan > .secrets.baseline
git add .pre-commit-config.yaml .secrets.baseline
pre-commit run --all-files
```

---

## Required Tools

| Tool | Purpose | Install |
|------|---------|---------|
| `pre-commit` | Hook runner | `uv add --dev pre-commit` |
| `detect-secrets` | Pattern-based secret detection | `uv add --dev detect-secrets` |

---

## Setup Steps

### 1. Install tools

```bash
uv add --dev pre-commit detect-secrets
```

### 2. Copy the hook configuration

```bash
cp templates/.pre-commit-config.yaml .pre-commit-config.yaml
```

### 3. Create the secrets baseline

Scan the existing codebase to establish a baseline of known non-secret patterns:

```bash
detect-secrets scan > .secrets.baseline
```

Commit both files before installing hooks:

```bash
git add .pre-commit-config.yaml .secrets.baseline
git commit -m "chore: add secret scanning pre-commit hooks"
```

### 4. Install hooks

```bash
pre-commit install
```

Hooks now run automatically on every `git commit`.

### 5. Verify all files pass

```bash
pre-commit run --all-files
```

---

## Hooks Included

| Hook | Source | Purpose |
|------|--------|---------|
| `detect-secrets` | Yelp/detect-secrets | Pattern-based secret detection |
| `detect-private-key` | pre-commit-hooks | RSA/EC private key detection |
| `check-added-large-files` | pre-commit-hooks | Block accidental binary commits (>500 KB) |
| `check-merge-conflict` | pre-commit-hooks | Catch unresolved merge conflict markers |

---

## Updating the Baseline

When `detect-secrets` flags a false positive:

1. Audit the flagged line — confirm it is not a real secret.
2. Update the baseline to mark it as allowed:

```bash
detect-secrets scan --baseline .secrets.baseline
```

3. Commit the updated baseline with a comment explaining the false positive.

---

## Keeping Hooks Current

```bash
pre-commit autoupdate
git add .pre-commit-config.yaml
git commit -m "chore: update pre-commit hook versions"
```

Run quarterly or whenever a CVE affects a hook dependency.

---

## CI Enforcement

Once a CI pipeline exists, add this step before any build step:

```yaml
- name: Run pre-commit hooks
  run: |
    pip install pre-commit
    pre-commit run --all-files
```

This scan must pass before any other job may proceed.

---

## If a Secret Is Accidentally Committed

**This is a security incident. Act immediately — do not delay to finish other work.**

1. **Rotate the credential.** Revoke and reissue before anything else. Assume it is
   already compromised.

2. **Scrub the history** using BFG Repo Cleaner (preferred over `git filter-branch`):

```bash
# Replace a specific string across all history:
java -jar bfg.jar --replace-text secrets.txt my-repo.git

# Or delete a specific file from all history:
java -jar bfg.jar --delete-files <filename> my-repo.git

# Then clean up refs and force-push:
cd my-repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force-with-lease
```

3. **Force-push** requires human approval (RULES.md §6). Do not proceed unilaterally.

4. **Notify all parties** with a clone — they may have the secret cached locally.

5. **Audit access logs** — determine whether the exposed credential was used.

6. **Document the incident** — add a timestamped entry to the project's incident log or PR.

---

## Credential Rotation Scheduling

Agents must alert when credentials are approaching expiration and must never
silently allow an expired credential to remain in use.

### Rotation Schedule Defaults

| Credential type | Maximum lifetime | Alert at |
|----------------|-----------------|---------|
| API tokens (third-party services) | 90 days | 14 days before expiry |
| Database passwords | 180 days | 30 days before expiry |
| PyPI tokens | 365 days | 30 days before expiry |
| CI/CD secrets (GitHub Actions) | 365 days | 30 days before expiry |
| SSH deploy keys | 365 days | 30 days before expiry |
| TLS certificates | Per CA (≤ 398 days) | 30 days before expiry |

Override defaults in the project's `AGENTS.md` with a written rationale.

### Detecting Expiry

Where the credential provider exposes an expiry date, record it in a
`.credential-manifest.json` at project root (never committed — add to `.gitignore`):

```json
{
  "credentials": [
    {
      "name": "THIRD_PARTY_API_TOKEN",
      "env_var": "THIRD_PARTY_API_TOKEN",
      "issued": "2026-01-15",
      "expires": "2026-04-15",
      "rotation_alert_days": 14
    }
  ]
}
```

Check expiry programmatically:

```python
import json
from datetime import date, timedelta
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


def check_credential_expiry(manifest_path: Path = Path(".credential-manifest.json")) -> None:
    """Log warnings for credentials approaching expiration.

    Raises:
        RuntimeError: If any credential is already expired.
    """
    if not manifest_path.exists():
        return
    manifest = json.loads(manifest_path.read_text())
    today = date.today()
    for cred in manifest.get("credentials", []):
        expires = date.fromisoformat(cred["expires"])
        alert_at = expires - timedelta(days=cred.get("rotation_alert_days", 14))
        if today >= expires:
            raise RuntimeError(
                f"Credential '{cred['name']}' expired on {expires}. Rotate immediately."
            )
        if today >= alert_at:
            logger.warning(
                "Credential approaching expiration",
                name=cred["name"],
                expires=str(expires),
                days_remaining=(expires - today).days,
            )
```

Call `check_credential_expiry()` at application startup and as a CI step.

### Rotation Procedure

1. Generate the new credential in the provider's console.
2. Update the secret in all environments (GitHub Actions secrets, `.env` on each host).
3. Verify the application starts cleanly with the new credential.
4. Revoke the old credential in the provider's console.
5. Update `expires` in `.credential-manifest.json` and commit the manifest file update
   (the manifest file itself is gitignored; commit only the `.gitignore` entry).
6. Log the rotation in the project's incident/maintenance log.
