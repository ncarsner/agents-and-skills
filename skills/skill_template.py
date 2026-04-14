"""
Skill Template

Boilerplate for creating a new skill for use with agents.
Copy this file, rename it, and implement the methods below.
"""


class BaseSkill:
    """Base class for all skills."""

    name: str = "base_skill"
    description: str = "A base skill template."

    def execute(self, input_text: str) -> str:
        """
        Execute the skill on the given input.

        Args:
            input_text: The text or context passed from the agent.

        Returns:
            The skill's output as a string.
        """
        raise NotImplementedError("Subclasses must implement execute()")


class ExampleSkill(BaseSkill):
    """
    Example skill that demonstrates how to implement a custom skill.

    Replace this docstring and the execute() method with your own logic.
    """

    name = "example_skill"
    description = "An example skill that echoes its input in uppercase."

    def execute(self, input_text: str) -> str:
        return f"[{self.name}] {input_text.upper()}"
