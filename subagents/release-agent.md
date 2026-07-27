# Release Agent Instructions

This file extends `CLAUDE.md` with instructions specific to publishing
**Python packages to PyPI**. Read root `CLAUDE.md` and `RULES.md` first.

---

## Purpose

The release agent manages the end-to-end workflow for cutting a versioned
release: bumping version, updating `CHANGELOG.md`, building and publishing
the distribution, and tagging the commit. It never bypasses CI gates.

---

## Versioning Policy

Follow [Semantic Versioning 2.0.0](https://semver.org/):

| Change type | Version bump | Example |
|-------------|-------------|---------|
| Breaking change to public API | MAJOR | 1.2.3 → 2.0.0 |
| New backward-compatible feature | MINOR | 1.2.3 → 1.3.0 |
| Bug fix, patch, or dependency bump | PATCH | 1.2.3 → 1.2.4 |

Rules:
- Version lives in `pyproject.toml` under `[project] version`.
- Never set `version = "0.0.0"` in production; start at `0.1.0` for pre-release,
  `1.0.0` when the public API is stable.
- Do not use `setuptools-scm` or dynamic versioning unless explicitly authorized.
- Pre-release identifiers: `1.0.0a1`, `1.0.0b1`, `1.0.0rc1`.

---

## CHANGELOG.md Format

Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

```markdown
# Changelog

## [Unreleased]

### Added
- Short description of new feature.

### Changed
- Short description of changed behavior.

### Fixed
- Short description of bug fix.

## [1.2.3] — 2026-05-15

### Fixed
- Corrected off-by-one error in pagination helper.

[Unreleased]: https://github.com/org/repo/compare/v1.2.3...HEAD
[1.2.3]: https://github.com/org/repo/compare/v1.2.2...v1.2.3
```

Rules:
- Every user-visible change goes in `[Unreleased]` during development.
- When cutting a release, rename `[Unreleased]` to `[X.Y.Z] — <date>` and add a
  new empty `[Unreleased]` section above it.
- Use exactly these subsections: `Added`, `Changed`, `Deprecated`, `Removed`,
  `Fixed`, `Security`. Do not invent new subsection names.
- Keep entries short (one sentence). Do not include internal refactors unless they
  affect public API behavior.

---

## Required CI Gates Before Release

All of the following must pass on the release commit before tagging:

```bash
pre-commit run --all-files          # secret scanning (RULES.md §8)
ruff check .                        # no lint errors
mypy src/                           # no type errors
python3 -m pytest --cov=src --cov-fail-under=100   # 100% coverage
pip-audit                           # no known dependency vulnerabilities
```

A release tag must not be created if any gate fails. No exceptions.

---

## Build and Publish Workflow

### 1. Verify clean working tree

```bash
git status          # must be clean
git log --oneline -5
```

### 2. Bump version in `pyproject.toml`

Edit `[project] version` manually. Then verify the package builds cleanly:

```bash
uv build
```

The `dist/` directory must contain both a `.tar.gz` (sdist) and a `.whl` (wheel).

### 3. Update CHANGELOG.md

- Move all items from `[Unreleased]` into the new versioned section.
- Add comparison links at the bottom.
- Commit: `chore: release vX.Y.Z`.

### 4. Tag the release

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin main --tags
```

### 5. Publish to PyPI

```bash
uv publish
```

`uv publish` reads credentials from the environment. Never pass tokens on the
command line or store them in any file.

#### Credential storage

| Environment | Token source |
|-------------|-------------|
| Local dev | `PYPI_TOKEN` env var (set in shell; never in `.env` file) |
| GitHub Actions | `secrets.PYPI_TOKEN` repository secret |

GitHub Actions publish step:

```yaml
- name: Publish to PyPI
  env:
    UV_PUBLISH_TOKEN: ${{ secrets.PYPI_TOKEN }}
  run: uv publish
```

Fallback (if `uv publish` is unavailable): `twine upload dist/*` with
`TWINE_PASSWORD` set from the same secret. Do not use `--skip-existing`.

### 6. Create GitHub Release

```bash
gh release create vX.Y.Z dist/* \
  --title "vX.Y.Z" \
  --notes "$(sed -n '/## \[X.Y.Z\]/,/## \[/p' CHANGELOG.md | head -n -1)"
```

Attach the `dist/` artifacts to the release.

---

## PyPI Token Security

- Tokens are scoped to a single project — never use an account-wide token.
- Rotate tokens immediately if exposed. Report via `skills/secret-scanning.md`
  incident procedure.
- Store only in GitHub Actions secrets or a local secrets manager (`pass`,
  `1Password CLI`). Never commit, log, or print.

---

## Pre-release Checklist

- [ ] Version bumped in `pyproject.toml`
- [ ] `CHANGELOG.md` updated: `[Unreleased]` → `[X.Y.Z] — <date>`
- [ ] All CI gates pass on the release commit
- [ ] `uv build` produces `.whl` and `.tar.gz` without errors
- [ ] `git tag vX.Y.Z` created and pushed
- [ ] `uv publish` succeeded; package visible on PyPI within 5 minutes
- [ ] GitHub Release created with `dist/` artifacts attached
- [ ] New empty `[Unreleased]` section added to `CHANGELOG.md`

---

## See Also

- [`RULES.md §7`](../RULES.md#7-testing-and-coverage) — 100% coverage gate
- [`RULES.md §8`](../RULES.md#8-security-and-secrets) — secret scanning before release
- [`skills/python-uv-workflow.md`](../skills/python-uv-workflow.md) — `uv` package manager reference
- [`skills/secret-scanning.md`](../skills/secret-scanning.md) — token incident response
