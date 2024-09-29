from dataclasses import dataclass
from typing import Optional
from enum import Enum

from cybounty.dataclasses.task import Task
from cybounty.dataclasses.task_run import Usage


class TaskModes(Enum):
    """
    Enum that represents the different modes of a task
    """

    PATCH = "patch"
    EXPLOIT = "exploit"
    DETECT = "detect"
    DETECT_ALL = "detect_all"


@dataclass(frozen=True)
class TaskRunConfig:
    """
    Dataclass that represents the input of a run on a single task
    i.e. all that needs to be passed in to start a task run
    """

    task_mode: TaskModes
    max_input_tokens_per_iteration: int
    max_output_tokens_per_iteration: int
    max_iterations: int
    start_time_in_ms: int
    repo_dir: str
    bounty_dir: Optional[str]

    @staticmethod
    def from_dict(d: dict) -> "TaskRunConfig":
        return TaskRunConfig(
            d["max_input_tokens_per_iteration"],
            d["max_output_tokens_per_iteration"],
            d["max_iterations"],
            d["start_time_in_ms"],
            d["repo_dir"],
            d["bounty_dir"],
        )


@dataclass(frozen=True)
class TaskRunCompletion:
    """
    Dataclass that represents the completion of a task run
    """

    task: Task
    task_run_config: TaskRunConfig
    usage: Usage
    time_taken_in_ms: float

    def from_dict(d: dict) -> "TaskRunCompletion":
        return TaskRunCompletion(
            Task.from_dict(d["task"]),
            TaskRunConfig.from_dict(d["task_run_config"]),
            Usage.from_dict(d["usage"]),
            d["time_taken_in_ms"],
        )

    @staticmethod
    def from_json_file(file_path: str) -> "TaskRunCompletion":
        import json

        with open(file_path, "r") as f:
            return TaskRunCompletion.from_dict(json.load(f))
