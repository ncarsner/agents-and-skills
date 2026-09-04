---
name: prd
description: Synthesize the shared understanding from a grill-me session into a structured Product Requirements Document. Use after /grill-me has resolved the key decisions and the user is ready to formalize the plan.
disable-model-invocation: true
argument-hint: [project name or topic]
allowed-tools: Read Bash Write
---

Synthesize the current conversation into a Product Requirements Document for $ARGUMENTS (or the project discussed if no argument is given).

## PRD structure

Produce a document with these sections in order:

1. **Title**: one line, imperative
2. **Overview**: two sentences: what this is and why it exists
3. **Goals**: three to five measurable outcomes
4. **Non-goals**: explicit exclusions to prevent scope creep
5. **User stories**: `As a [role], I want [action] so that [value]`: one per major workflow
6. **Requirements**: numbered list; each requirement is independently testable
7. **Acceptance criteria**: checkbox list mapped to requirements
8. **Open questions**: unresolved items from the grill-me session

## Output

1. Write the PRD in markdown to `plans/<project-name>-prd.md`.
2. Also write a task list in JSON to `plans/<project-name>-prd.json` following the schema in `plans/prd.json`: one entry per requirement with `task`, `category`, `priority`, `done`, `description`, `files_affected`, `acceptance_criteria`, and `steps` fields.
3. Confirm both files written. Then output:

PIPELINE GATE: PRD written. Do not begin implementation.
The human must invoke `/prd-to-issues plans/<project-name>-prd.md` to continue.
No code changes may occur until GitHub issues exist.

Constraints:
- Do not fabricate decisions not established in the conversation.
- If a section cannot be filled from the conversation, write `TBD, resolve before development starts`.
- Never skip the Open questions section.
