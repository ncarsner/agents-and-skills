# agents-and-skills

Boilerplate repo for developing AGENTS and SKILLS markdown reference files for agentic coding.

## Structure

```
agents-and-skills/
├── agents/
│   └── agents.md   # Agent protocol, directives, and template for new agents
├── skills/
│   └── skills.md   # Skill registry, invocation contract, and template for new skills
└── README.md
```

## Purpose

This repository provides human- and machine-readable markdown reference files that coding agents can read to understand:

- **How agents should behave** — decision-making rules, escalation paths, output formats.
- **What skills are available** — a registry of discrete capabilities agents can invoke.
- **How to extend the system** — templates for adding new agents and skills.

## Getting Started

### Reading the References

Agents should load and internalize these files before executing any task:

1. `agents/agents.md` — defines the base agent protocol all agents must follow.
2. `skills/skills.md` — lists all registered skills with their input/output contracts.

### Adding a New Agent

Follow the template at the bottom of `agents/agents.md` and create a new file in the `agents/` directory:

```
agents/
└── <agent-name>.md
```

### Adding a New Skill

Add an entry to the skill registry in `skills/skills.md` following the template at the bottom of that file.

