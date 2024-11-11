import pytest

from tests.docker_helper import DockerHelper
from tests.logger import logger
from tests.util import run_exploit_script, run_verify_script


@pytest.fixture(scope="session")
def dirs(request):
    return request.config.getoption("--dirs")


@pytest.fixture(scope="session")
def docker_helper():
    return DockerHelper()


def test_patch_workflow(dirs, docker_helper):
    """Test exploits within given directories."""
    if not dirs:
        logger.info("No directories provided. Skipping tests.")
        return

    for i, dir_path in enumerate(dirs):
        run_exploit_script(dir_path, docker_helper)


def patch_workflow(path, docker_helper):
    logger.info(f"Running patch workflow for {path}")

    logger.info(
        f"Running verify script for {path} before executing the exploit")
    verify_result = run_verify_script(path)
    if verify_result != 1:
        logger.error(
            f"Verify script failed for {path} before exploit execution.\n Verify should return with exit code 1 but returned {verify_result}.")
        pytest.fail(
            f"Verify script succeeded for {path} before exploit execution.")

    logger.info(f"Running exploit for {path}")
    run_exploit_script(path, docker_helper)

    logger.info(
        f"Running verify script for {path} after executing the exploit")
    verify_result = run_verify_script(path)
    if verify_result != 1:
        logger.error(
            f"Verify script succeeded for {path} after exploit execution.\n Verify should return with exit code 1 but returned {verify_result}.")
        pytest.fail(
            f"Verify script succeeded for {path} after exploit execution in the patch workflow.")
