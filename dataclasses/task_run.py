from dataclasses import dataclass
from enum import Enum
from typing import List, Optional, Union
from cybounty.dataclasses.task import Task, TaskModes

@dataclass(frozen=True)
class TaskRun:
    """
    Dataclass that represents an agent run, which consists of a list of iterations
    """

    task: "Task"
    iterations: List["Iteration"]
    score_metric: dict[TaskModes, float]
    time_taken_in_ms: float
    completion_status: "CompletionStatus"

    @staticmethod
    def from_dict(d: dict) -> "TaskRun":
        score_metric = {}

        # Map task modes to their respective score fields
        for mode, values in d["score_metric"].items():
            task_mode = TaskModes[mode]

            if task_mode == TaskModes.PATCH:
                score_metric[task_mode] = values["patch_bounty"]

            elif task_mode == TaskModes.EXPLOIT:
                score_metric[task_mode] = values["exploit_score"]

            elif task_mode in {TaskModes.DETECT_LESS_INFO, TaskModes.DETECT_SOME_INFO}:
                score_metric[task_mode] = values["disclosure_bounty"]

            elif task_mode == TaskModes.DETECT_ALL:
                score_metric[task_mode] = values["detect_all_score"]

        return TaskRun(
            [Iteration.from_dict(iteration) for iteration in d["iterations"]],
            score_metric,
            d["time_taken_in_ms"],
            CompletionStatus(d["completion_status"]),
        )


@dataclass(frozen=True)
class Usage:
    """
    Dataclass that represents token and iteration usage
    """

    input_tokens_used: int
    output_tokens_used: int
    total_tokens: int
    iterations_used: int

    @staticmethod
    def from_dict(d: dict) -> "Usage":
        return Usage(
            d["input_tokens_used"],
            d["output_tokens_used"],
            d["total_tokens"],
            d["iterations_used"],
        )


@dataclass(frozen=True)
class Iteration:
    """
    Dataclass that represents a single iteration of a run
    """

    model_input: "ModelInput"
    model_response: "ModelResponse"
    execution_output: Union["CommandExecutionOutput", None]

    @staticmethod
    def from_dict(d: dict) -> "Iteration":
        return Iteration(
            ModelInput.from_dict(d["model_input"]),
            ModelResponse.from_dict(d["model_response"]),
            CommandExecutionOutput.from_dict(d["execution_output"]),
        )


@dataclass(frozen=True)
class CommandExecutionOutput:
    """
    Dataclass that represents the output corresponding to a command execution
    """

    command: "Command"
    stdout: Union[str, None]
    stderr: Union[str, None]

    @staticmethod
    def from_dict(d: dict) -> "CommandExecutionOutput":
        return CommandExecutionOutput(
            Command(
                CommandType(d["command"]["command_type"]), d["command"]["command_str"]
            ),
            d["stdout"],
            d["stderr"],
        )


@dataclass(frozen=True)
class Command:
    """
    Dataclass that represents a command that the llm outputs
    """

    command_type: "CommandType"
    command_str: str


class CommandType(int, Enum):
    """
    Types of commands, e.g. shell command, vs answer 
    """

    shell_command = 0
    answer = 1

    def __str__(self):
        return self.name


class CompletionStatus(str, Enum):
    not_answered = "not_answered"
    answered = "answered"

    def __str__(self):
        return self.name


@dataclass(frozen=True)
class ModelInput:
    """
    Dataclass of model input
    """

    value: str
    num_tokens: int

    @staticmethod
    def from_dict(d: dict) -> "ModelInput":
        return ModelInput(value=d["value"], num_tokens=d["num_tokens"])


@dataclass(frozen=True)
class ModelResponse:
    """
    Dataclass of model response
    """

    value: str
    full_response: Optional[str]
    time_taken_in_ms: float
    num_tokens: int

    @staticmethod
    def from_dict(d: dict) -> "ModelResponse":
        return ModelResponse(d["value"], d["full_response"], d["time_taken_in_ms"], d["num_tokens"])

