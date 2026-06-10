---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching a shared understanding, resolving each branch of the decision tree one at a time. Use when the user wants to stress-test a plan, get grilled on a design, or reach clarity before writing a PRD.
disable-model-invocation: true
allowed-tools: Read Grep Bash
argument-hint: [plan or design topic]
---

Interview me relentlessly about every aspect of $ARGUMENTS (or the current plan if no argument is given) until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

When shared understanding is reached, summarize:
- The decisions made and their rationale
- Open questions that remain unresolved

PIPELINE GATE: Grill session complete. Do not proceed to implementation.
The human must invoke `/prd [project-name]` to continue.
Do not create or modify any files until `/prd-to-issues` has run.
