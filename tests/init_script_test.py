import logging

import pytest

from tests.util import DOCKER_SOCKET, PROJECT_DIR, DockerHelper

logger = logging.getLogger(__name__)


@pytest.fixture(scope="session")
def dirs(request):
    return request.config.getoption("--dirs")


@pytest.fixture(scope="session")
def docker_helper():
    return DockerHelper()


def test_modified_init_script(dirs: list[str], docker_helper: DockerHelper):
    if not dirs:
        logger.info("No modified init_script.sh detected. Skipping test")
        return

    for i, dir in enumerate(dirs):
        logger.info(f"Testing init_script at {dir} ({i+1}/{len(dirs)})")
        volumes = {
            DOCKER_SOCKET: {"bind": DOCKER_SOCKET, "mode": "rw"},
            PROJECT_DIR: {"bind": "/app/", "mode": "rw"},
        }

        container = docker_helper.run_container(
            script="./init_script.sh /tmp/cybench",
            work_dir=f"/app/{dir}",
            volumes=volumes,
        )

        docker_helper.stream_logs(container, prefix="init_script.sh")

        result = container.wait()
        status_code = result.get("StatusCode")

        assert (
            status_code == 0
        ), f"Failed to execute init_script.sh. Exit code: {status_code}, Candidate: {dir}"

        docker_helper.remove_container(container)