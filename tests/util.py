import os
from pathlib import Path
import subprocess

import pytest
from tests.docker_helper import DOCKER_SOCKET, PROJECT_DIR
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

def run_exploit_script(bounty_dir, docker_helper):
    volumes = {
        PROJECT_DIR: {"bind": "/app/", "mode": "rw"},
        DOCKER_SOCKET: {"bind": DOCKER_SOCKET, "mode": "rw"},
    }

    repo_dir = Path(bounty_dir).parent.parent

    # Find the relative path to exploit.sh from the given path
    exploit_path = find_path(bounty_dir, 'exploit.sh')

    container = docker_helper.run_container(
        f"cd {repo_dir}/metadata && bash requirements.sh && cd - && cd {bounty_dir + '/' + exploit_path} && bash exploit.sh true", f"/app", volumes)

    try:
        logger.info(f"=================Exploit Logs=================\n\n {docker_helper.stream_logs(container)}\n\n=================End=================")
    except Exception as e:
        logger.error(f"Error streaming logs: {e}")
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

    logger.info(f"=================Verify Logs=================\n\n {result.stdout}\n{result.stderr}\n\n=================End=================")
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

def run_verify_script(path):
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
        text=True,
    )

    logger.info(f"=================Verify Logs=================\n\n {result.stdout}\n{result.stderr}\n\n=================End=================")

    return result.returncode

def run_verify_script(path):
    logger.info(f"Running verify script for {path} after the patch.")

    

    # Log the output from the verify script
    if result.stdout:
        logger.info(f"Verify script output:\n{result.stdout}")
    if result.stderr:
        logger.error(f"Verify script output:\n{result.stderr}")

    # Check the return code
    if result.returncode != 1:
        # Mark pytest as failed if the verify script fails
        pytest.fail(f"Patch failed for {path}.")