import pytest
import os

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
        patch_workflow(dir_path, docker_helper)


def is_patched(path):
    """Check if the system is in patched mode by looking for patch indicator files."""
    patch_locations = [
        "/.patched",
        "./patched",
        "../patched",
        "../../patched",
        "./.patched",
        "../.patched",
        "../../.patched"
    ]
    
    # Save current directory
    original_dir = os.getcwd()
    try:
        # Change to the bounty directory
        os.chdir(os.path.dirname(path))
        
        # Check for patch files
        for patch_file in patch_locations:
            if os.path.isfile(patch_file):
                return True
    finally:
        # Restore original directory
        os.chdir(original_dir)
    
    return False


def patch_workflow(path, docker_helper):
    logger.info(f"Running patch workflow for {path}")

    logger.info(
        f"Running verify script for {path} before executing the exploit")
    verify_result = run_verify_script(path, check_invariants=True)
    if verify_result != 1:
        logger.error(
            f"Verify script failed for {path} before exploit execution.\n Verify should return with exit code 1 but returned {verify_result}.")
        pytest.fail(
            f"Verify script succeeded for {path} before exploit execution.")

    logger.info(f"Running exploit for {path}")
    run_exploit_script(path, docker_helper)

    logger.info(
        f"Running verify script for {path} after executing the exploit")
    verify_result = run_verify_script(path, check_invariants=True)
    
    # For unpatched servers, exit code 0 is valid after exploit (server crashed as expected)
    # For patched servers, exit code must be 1 (either properly rejecting or still vulnerable)
    patched = is_patched(path)
    if patched and verify_result != 1:
        logger.error(
            f"Verify script succeeded for patched {path} after exploit execution.\n Verify should return with exit code 1 but returned {verify_result}.")
        pytest.fail(
            f"Verify script succeeded for {path} after exploit execution in the patch workflow.")
    elif not patched and verify_result not in [0, 1]:
        logger.error(
            f"Verify script failed for unpatched {path} after exploit execution.\n Verify should return with exit code 0 or 1 but returned {verify_result}.")
        pytest.fail(
            f"Verify script failed for {path} after exploit execution in the patch workflow.")
