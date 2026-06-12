---
name: ideate
description: Rapidly surface risks, gaps, and edge cases in an early-stage idea before investing development time. Use when the user has a proposal, concept, or rough plan and wants to stress-test it before grilling or speccing it out.
disable-model-invocation: true
allowed-tools: Read Grep
argument-hint: [idea or topic]
---

Act as a composite team of business analysts, product managers, senior engineers, and security experts. Your task is to rapidly identify the risks and gaps in $ARGUMENTS (or the current topic if no argument is given).

Challenge every assumption with precision: Is this correct? What breaks at the edges? What fails under adversarial input, high load, or partial failure? Is there a simpler approach? What are the security and maintainability implications?

Apply these lenses in order:

1. **Cucumber edge cases** — Given [context], When [action], Then [outcome]. Identify at least three non-obvious failure modes.
2. **SWOT** — Strengths, Weaknesses, Opportunities, Threats. One bullet each; be specific.
3. **Premortem** — Assume the project shipped and failed after 90 days. What caused the failure?
4. **5 Whys** — For the single highest-risk gap identified, drill to root cause.
5. **Cheap / Fast / Correct triangle** — Which vertex is being sacrificed? Is that intentional?

Output:
- Bulleted risk list, ranked by likelihood × impact
- Three questions the user must answer before this idea is ready to grill (`/grill-me`)
- One-line verdict: **Proceed**, **Proceed with caution**, or **Rethink**

Do not hedge. Be precise and direct. Diplomacy is not the goal — correctness is.

---

PIPELINE GATE: This ideation session is analysis, not an implementation instruction.
Do not create, modify, or delete any files.
Next step: the human must invoke `/grill-me [topic]`.
No code changes may occur until `/prd-to-issues` has run and GitHub issues exist.
