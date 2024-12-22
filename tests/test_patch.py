# tests/test_patch.py
import pytest
from tests.docker_helper import DockerHelper
from tests.logger import logger
from tests.util import run_exploit_script, run_verify_script

def pytest_addoption(parser):
    parser.addoption(
        "--dirs",
        action="append",
        default=[],
        help="List of bounty directories to test (patch)."
    )

def pytest_generate_tests(metafunc):
    if "dir_path" in metafunc.fixturenames:
        dirs = []
        for d in metafunc.config.getoption("dirs"):
            dirs.extend(d.strip().split())
        if dirs:
            metafunc.parametrize("dir_path", dirs, ids=dirs)

@pytest.fixture(scope="session")
def docker_helper():
    return DockerHelper()

def patch_workflow(path, docker_helper):
    logger.info(f"Running patch workflow for {path}")

    logger.info(f"Running verify script for {path} before executing the exploit. Verify should fail.")
    verify_result = run_verify_script(path)
    if verify_result != 1:
        logger.error(
            f"Verify script failed for {path} before exploit execution.\n"
            f"Verify should return with exit code 1 but returned {verify_result}."
        )
        pytest.fail(
            f"Verify script succeeded for {path} before exploit execution."
        )
    else:
        logger.info(f"Verify failed with exit code {verify_result} as expected.")

    logger.info(f"Running exploit for {path}")
    run_exploit_script(path, docker_helper)

    logger.info(
        f"Running verify script for {path} after executing the exploit. Verify should fail.")
    verify_result = run_verify_script(path)
    if verify_result != 1:
        logger.error(
            f"Verify script succeeded for {path} after exploit execution.\n"
            f"Verify should return with exit code 1 but returned {verify_result}."
        )
        pytest.fail(
            f"Verify script succeeded for {path} after exploit execution in patch workflow."
        )
    else:
        logger.info(f"Verify failed with exit code {verify_result} as expected.")


@pytest.mark.usefixtures("docker_helper")
def test_patch_workflow(dir_path, docker_helper):
    patch_workflow(dir_path, docker_helper)
