# agents-and-skills

Boilerplate repo for developing AGENTS and SKILLS files for agentic coding.

## Structure

```
agents-and-skills/
├── agents/
│   └── agent_template.py   # Base agent class and example implementation
├── skills/
│   └── skill_template.py   # Base skill class and example implementation
└── README.md
```

## Getting Started

### Create a Skill

1. Copy `skills/skill_template.py` to a new file (e.g. `skills/my_skill.py`).
2. Subclass `BaseSkill`, set `name` and `description`, and implement `execute()`.

```python
from skills.skill_template import BaseSkill

class MySkill(BaseSkill):
    name = "my_skill"
    description = "Does something useful."

    def execute(self, input_text: str) -> str:
        # Your logic here
        return f"Result for: {input_text}"
```

### Create an Agent

1. Copy `agents/agent_template.py` to a new file (e.g. `agents/my_agent.py`).
2. Subclass `BaseAgent`, set `name` and `description`, and implement `run()`.

```python
from agents.agent_template import BaseAgent

class MyAgent(BaseAgent):
    name = "my_agent"
    description = "An agent that uses my custom skills."

    def run(self, task: str) -> str:
        # Your logic here, optionally calling self.skills
        return f"Agent handled: {task}"
```

### Wire an Agent with Skills

```python
from agents.my_agent import MyAgent
from skills.my_skill import MySkill

agent = MyAgent(skills=[MySkill()])
result = agent.run("Do something useful")
print(result)
```
