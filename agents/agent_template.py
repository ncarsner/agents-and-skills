"""
Agent Template

Boilerplate for creating a new agentic coding assistant.
Copy this file, rename it, and implement the methods below.
"""

from skills.skill_template import BaseSkill


class BaseAgent:
    """Base class for all agents."""

    name: str = "base_agent"
    description: str = "A base agent template."

    def __init__(self, skills: list[BaseSkill] | None = None):
        self.skills: list[BaseSkill] = skills or []

    def add_skill(self, skill: BaseSkill) -> None:
        """Register a skill with this agent."""
        self.skills.append(skill)

    def run(self, task: str) -> str:
        """
        Execute the agent on a given task.

        Args:
            task: A natural-language description of the task to perform.

        Returns:
            The agent's response or result as a string.
        """
        raise NotImplementedError("Subclasses must implement run()")


class ExampleAgent(BaseAgent):
    """
    Example agent that demonstrates how to implement a custom agent.

    Replace this docstring and the methods below with your own logic.
    """

    name = "example_agent"
    description = "An example agent that echoes its input."

    def run(self, task: str) -> str:
        results = []
        for skill in self.skills:
            result = skill.execute(task)
            results.append(result)
        if results:
            return "\n".join(results)
        return f"[{self.name}] No skills available to handle: {task}"
