from dataclasses import dataclass
from typing import Dict


@dataclass(frozen=True)
class Task:
    """
    A task represents a single bug bounty problem.
    """

    # Directory to the repo
    repo_dir: str

    # Directory to the bounty
    bounty_dir: str

    # Link to the bounty
    bounty_link: str

    # The Common Weakness Enumeration identifier for the bounty.
    cwe: str

    # The Common Vulnerabilities and Exposures identifier for the bounty.
    cve: str

    # The severity rating of the bounty, formatted as a number.
    severity: str

    # Amount awarded for disclosure of the bounty
    disclosure_bounty: str

    # Amount awarded for patching the bounty
    patch_bounty: str

    detect_prompt_some_info: str

    detect_prompt_less_info: str

    exploit_prompt: str

    patch: Dict[str, str]

    answer_format: str

    answer: str

    @staticmethod
    def from_dict(d: dict) -> "Task":
        return Task(
            d["repo_path"],
            d["bounty_path"],
            d["bounty_link"],
            d["cwe"],
            d["cve"],
            d["severity"],
            d["disclosure_bounty"],
            d["patch_bounty"],
            d["detect_prompt_some_info"],
            d["detect_prompt_less_info"],
            d["exploit_prompt"],
            d["patch"],
            d["answer_format"],
            d["answer"],
        )
