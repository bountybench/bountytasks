import os
import shutil
import subprocess
from pathlib import Path

import pytest

from tests.docker_helper import DOCKER_SOCKET, PROJECT_DIR
from tests.logger import logger, LOG, ERROR


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

def copy_files(exploit_path, codebase_dir):
    # Ensure the destination directory exists
    os.makedirs(codebase_dir, exist_ok=True)

    # Walk through all files and subdirectories in exploit_path
    for root, dirs, files in os.walk(exploit_path):
        for file in files:
            src_path = os.path.join(root, file)
            # Calculate destination path
            rel_path = os.path.relpath(src_path, exploit_path)
            dst_path = os.path.join(codebase_dir, rel_path)
            
            # Ensure the destination directory exists
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            
            # Copy the file
            shutil.copy2(src_path, dst_path)
    logger.info(f"Copied {src_path} to {dst_path}")


def run_exploit_script(bounty_dir, docker_helper):
    volumes = {
        PROJECT_DIR: {"bind": "/app/", "mode": "rw"},
        DOCKER_SOCKET: {"bind": DOCKER_SOCKET, "mode": "rw"},
    }

    repo_dir = Path(bounty_dir).parent.parent
    codebase_dir = repo_dir / 'codebase'

    # Find the relative path to exploit.sh from the given path
    exploit_path = find_path(bounty_dir, 'exploit.sh')
    copy_files(Path(exploit_path).resolve(), codebase_dir)

    logger.info(f"Running exploit script at {codebase_dir}")
    container = docker_helper.run_container(
        f"cd {codebase_dir} && ls && bash exploit.sh true", f"/app", volumes)

    try:
        logger.info(LOG.format("Exploit", docker_helper.stream_logs(container)))
    except Exception as e:
        logger.error(ERROR)
        logger.error(f"Error streaming logs: {e}")
    finally:
        container.remove()


def run_verify_script(path):
    # Find the relative path to the verify.sh from the given path
    verify_path = find_path(path, 'verify.sh')

    # Run the verify script and capture the exit code
    verify_result = subprocess.run(
        ["bash", "./verify.sh"],
        cwd=path + "/" + verify_path,
        capture_output=True,
        text=True
    )

    logger.info(LOG.format("Verify", verify_result.stdout + '\n' + verify_result.stderr))

    return verify_result.returncode
