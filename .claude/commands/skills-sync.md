---
description: Sync skills from all ~/Code project AGENTS/skills/ directories into agents-and-skills/skills/
allowed-tools: Bash(find *), Bash(grep *), Read, Edit, Write
---

Scan every project under `~/Code/` for skill files in `AGENTS/skills/` and merge any new
content into this repo's `skills/` directory.

## Step 1: Discover all project-specific skill files

!`find ~/Code -path "*/AGENTS/skills/*.md" -not -path "*/agents-and-skills/*" -type f | sort`

## Step 2: For each discovered file, classify it

For each file found above, get its basename and check whether `skills/<basename>` exists
in this repo.

**New file** (no counterpart in `skills/`):
- Read the source file.
- Write it verbatim to `skills/<basename>`.
- Mark it as "added" in the report.

**Existing file** (counterpart already in `skills/`):
- Run `grep "^## " <source>` and `grep "^## " skills/<basename>` to get the heading sets.
- Compute new headings = headings in source not present in base.
- Exclude `See Also` from consideration (it's boilerplate).
- For each new heading: extract the full section (from that `##` line to the next `##` line
  or end of file) from the source file, then append it to the base file immediately before
  the `## See Also` section, or at the end of the file if no `See Also` exists.
- Mark it as "updated — sections added: <list>" in the report.

**In sync** (base file already contains all headings from source):
- No action. Mark it as "already in sync" in the report.

## Step 3: Update skills/skills.md for new files only

For each newly added file:
- Read the file to determine domain and purpose.
- Add one row to the Reference Files table in `skills/skills.md`.
- Match the domain grouping order: All → DevOps → CLI → Web → Data/Web → NLP →
  Legal/Fiscal → Dashboards → Automation. Insert within the correct domain group.
- Keep "When to load" phrasing concise: short noun phrases, semicolon-separated.

## Step 4: Update subagents/registry.json for new files only

For each newly added file:
- Add one entry to the `skills` array in `subagents/registry.json`:
  `{"file": "skills/<basename>", "name": "<basename without .md>", "domain": "<domain>", "version": "1.0.0", "status": "active"}`.
- Use the same domain determined in Step 3, translated to the registry's lowercase
  hyphenated convention (e.g. "Data/Web" → `data-web`, "Legal/Fiscal" → `legal-fiscal`,
  "DevOps" → `devops`).
- If a file with the same `name` already exists in the array (should only happen if
  Step 2 misclassified something as new), do not add a duplicate — update its `version`
  instead and note the correction in the sync report.

## Step 5: Update CHANGELOG.md

Add a `## YYYY-MM-DD` entry at the top (use today's date). Include:
- **Added** — one bullet per new skill file, with the source project path in parentheses.
- **Changed** — one bullet per existing file that received new sections, listing the section
  names and source project path.
- Omit the section entirely if there are no changes of that type.

## Step 6: Print a sync report

```
Skills sync complete
====================
Added (N):
  - wikimedia-svg-sourcing.md  ← will-it-python/AGENTS/skills/

Updated (N):
  - legal-fiscal-analysis.md  +[Pattern: State-Machine Parsing…]  ← frc-tools/AGENTS/skills/

Already in sync (N):
  - <filename>  (<source project>)
```

If nothing changed across all files, say so explicitly: "All project skills already in sync with base."
