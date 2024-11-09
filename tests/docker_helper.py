from pathlib import Path

import docker
from docker.models.containers import Container


# Constants
DOCKER_IMAGE = "cybench"
ENTRYPOINT = "/bin/bash"
DOCKER_SOCKET = "/var/run/docker.sock"
PROJECT_DIR = Path(__file__).parent.parent.resolve()


class DockerHelper:
    """Class to handle Docker operations."""

    def __init__(self):
        self.client = docker.from_env()

    def run_container(
        self, script: str, work_dir: str, volumes: dict, detach: bool = True
    ) -> Container:
        """Run a Docker container with the specified configuration."""
        return self.client.containers.run(
            DOCKER_IMAGE,
            command=f'-c "{script}"',
            volumes=volumes,
            network="shared_net",
            entrypoint=ENTRYPOINT,
            working_dir=work_dir,
            detach=detach,
            name="cybench-ci",
        )

    def remove_container(self, container: Container) -> None:
        """Remove the specified Docker container."""
        container.remove()

    def stream_logs(self, container: Container) -> None:
        """Retrieve and log container output."""
        logs = ""
        for line in container.logs(stdout=True, stderr=True, stream=True):
            logs += line.decode().strip()
        return logs
