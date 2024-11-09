import os
from pathlib import Path
import subprocess

import pytest
from cybounty.tests.docker_helper import DOCKER_SOCKET, PROJECT_DIR, DockerHelper
from tests.logger import logger

def find_path(start_path, target):
    """
    Find the relative path to the target file from the given start path.
    Returns the relative path if found, None otherwise.
    """
    # Convert to absolute path and check if the path exists
    abs_start = os.path.abspath(start_path)
    if not os.path.exists(abs_start):
        pytest.fail(f"{start_path} does not exist.")

    # Walk through directory tree
    for root, dirs, files in os.walk(abs_start):
        if target in files:
            rel_path = os.path.relpath(root, abs_start)
            return rel_path

    pytest.fail(f"Could not find {target} in {start_path}.")

def run_exploit_script(path, docker_helper):
    volumes = {
        PROJECT_DIR: {"bind": "/app/", "mode": "rw"},
        DOCKER_SOCKET: {"bind": DOCKER_SOCKET, "mode": "rw"},
    }

    # Find the relative path to exploit.sh from the given path
    exploit_path = find_path(path, 'exploit.sh')

    run_verify_script(path, False)

    container = docker_helper.run_container(
        f"bash ../requirements.sh && cd {exploit_path} && ./exploit.sh", f"/app/{path}", volumes)

    try:
        docker_helper.stream_logs(container)
        run_verify_script(path, True)
    finally:
        container.remove()

def run_verify_script(path, exploit_status):
    if exploit_status:
        logger.info(
            f"Running verify script for {path} after executing the exploit")
    else:
        logger.info(
            f"Running verify script for {path} before executing the exploit")

    # Run the requirements.sh script to install dependencies
    result = subprocess.run(
        ["bash", "./requirements.sh"],
        cwd=Path(path).parent,
        capture_output=True,
        text=True,
    )

    # Find the relative path to the verify.sh from the given path
    verify_path = find_path(path, 'verify.sh')

    # Run the verify script and capture the exit code
    result = subprocess.run(
        ["bash", "./verify.sh"],
        cwd=path + "/" + verify_path,
        capture_output=True,
        text=True
    )

    # Log the output from the verify script
    if result.stdout:
        logger.info(f"Verify script output:\n{result.stdout}")
    if result.stderr:
        logger.error(f"Verify script error output:\n{result.stderr}")

    if exploit_status:
        # Check the return code
        if result.returncode != 0:
            # Mark pytest as failed if the verify script fails
            pytest.fail(
                f"Verify script failed for {path} after exploit execution.")
    else:
        # Check the return code
        if result.returncode != 1:
            # Mark pytest as failed if the verify script passes
            pytest.fail(
                f"Verify script passed for {path} before exploit execution.")