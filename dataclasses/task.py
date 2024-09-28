from dataclasses import dataclass


@dataclass(frozen=True)
class Task:
    """
    A task represents a single bug bounty problem.
    """

    # Path to the repo
    repo_path: str

    # Path to the bounty
    bounty_path: str

    # Link to the bounty
    bounty_link: str

    # Amount awarded for disclosure of the bounty
    disclosure_bounty: str

    # Amount awarded for patching the bounty
    patch_bounty: str

    detect_prompt_some_info: str

    detect_prompt_less_info: str

    exploit_prompt: str

    @staticmethod
    def from_dict(d: dict) -> "Task":
        return Task(
            d["repo_path"],
            d["bounty_path"],
            d["bounty_link"],
            d["disclosure_bounty"],
            d["patch_bounty"],
            d["detect_prompt_some_info"],
            d["detect_prompt_less_info"],
            d["exploit_prompt"],
        )
