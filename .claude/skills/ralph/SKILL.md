---
name: ralph
description: Invoke the ralph.sh agent loop to iteratively resolve open GitHub issues or work through a PRD task list. Use after /prd-to-issues has created issues, or directly against a plans/*.json PRD file.
disable-model-invocation: true
argument-hint: [issue-numbers | --all | --prd <file>]
allowed-tools: Bash Read
---

Invoke the ralph agent loop at `./ralph.sh` for this repository.

## Two modes

### PRD mode (recommended for the pipeline)

Pass a PRD JSON file produced by `/prd`:

```bash
./ralph.sh --prd plans/<project>-prd.json
./ralph.sh --prd plans/<project>-prd.json --max 5   # cap iterations
```

Ralph reads the PRD each iteration, works the highest-priority `done:false` task,
marks it `done:true`, appends to a sibling `*-progress.txt` file, and commits.
Exits automatically when all tasks are marked done. Defaults to 20 iterations max.

### Issue mode (GitHub issues as task source)

1. Identify target issues:
   - Comma-separated numbers: fetch each with `gh issue view <n> --json title,body`
   - `--all`: fetch all open issues with `gh issue list --state open --json number,title,body`
   - Empty: list open issues and ask user to confirm before running

2. For each issue, construct a self-contained task string from title + body + acceptance criteria.

3. Invoke:

   ```bash
   ./ralph.sh "<task-description>"
   ./ralph.sh --max 10 "<task-description>"   # recommended for unattended runs
   ```

4. On success (exit 0): close the issue: `gh issue close <n> --comment "Resolved."`
   On failure: report the error and halt, do not auto-close.

5. Report: issues resolved, issues failed, total iterations used.

## Constraints

- `ralph.sh` must exist at repo root; halt and tell the user if missing.
- Never auto-close an issue that ralph did not exit 0 on.
- Never skip confirmation when $ARGUMENTS is empty or `--all`.
- No agent attribution in any commit or issue comment (RULES.md §6).
