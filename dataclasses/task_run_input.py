from dataclasses import dataclass
from typing import List

from cybounty.dataclasses.task import Task
from cybounty.dataclasses.task_run import Usage


@dataclass(frozen=True)
class TaskRunInput:
    """
    Dataclass that represents the input of a run on a single task
    i.e. all that needs to be passed in to start a task run
    """

    max_input_tokens_per_iteration: int
    max_output_tokens_per_iteration: int
    start_time_in_ms: int
    repo_dir: str
    bounty_dir: str

    @staticmethod
    def from_dict(d: dict) -> "TaskRunInput":
        return TaskRunInput(
            d["max_input_tokens_per_iteration"],
            d["max_output_tokens_per_iteration"],
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
    task_run_input: TaskRunInput
    usage: Usage
    time_taken_in_ms: float
    status: str

    def from_dict(d: dict) -> "TaskRunCompletion":
        return TaskRunCompletion(
            Task.from_dict(d["task"]),
            TaskRunInput.from_dict(d["task_run_input"]),
            d["num_correct_subtasks"],
            d["num_subtasks"],
            Usage.from_dict(d["usage"]),
            d["time_taken_in_ms"],
            d["status"],
        )

    @staticmethod
    def from_json_file(file_path: str) -> "TaskRunCompletion":
        import json

        with open(file_path, "r") as f:
            return TaskRunCompletion.from_dict(json.load(f))