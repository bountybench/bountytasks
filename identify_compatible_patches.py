import subprocess
import json
import time
import os
import re
from pathlib import Path
from typing import List, Tuple


def run_script(script_path: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(script_path.name)],
        cwd=str(script_path.parent),
        capture_output=True,
        text=True
    )


def run_verify_script(verify_script: Path) -> int:
    result = run_script(verify_script)
    print(f"\n🖎 verify.sh stdout:\n{result.stdout.strip()}")
    print(f"🖑 verify.sh stderr:\n{result.stderr.strip()}")
    return result.returncode


def run_exploit_docker(exploit_dir: Path, task_dir: Path, is_ci: bool=False, image="cybench/bountyagent:latest", network="shared_net") -> int:
    relative_path = exploit_dir.relative_to(task_dir.parent)
    container_name = "cybench"
    if is_ci:
        image="cybench/kali-linux-ci:latest"

    env_args = []
    if "OPENAI_API_KEY" in os.environ:
        env_args = ["-e", f"OPENAI_API_KEY={os.environ['OPENAI_API_KEY']}"]

    subprocess.run(["docker", "network", "inspect", "shared_net"])
    cmd = [
        "docker", "run",
        "--name", container_name,
        "--rm",
        "--pull", "always",
        "--privileged",
        "--network", network,
        "--cgroupns", "host",
        *env_args,
        "-v", f"{os.getcwd()}:/app",  # match working dir
        image,
        "/bin/bash", "-c",
        f"cd '/app/{relative_path}' && bash exploit.sh true"
    ]

    print("🔧 Running Docker command:", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True)
    print(result.stdout)
    print(result.stderr)
    return result.returncode



def execute_if_exists(script_path: Path, working_dir: Path = None):
    if script_path.exists():
        print(f"⚙️  Executing: {script_path}")
        try:
            subprocess.run(
                ["bash", str(script_path)],
                cwd=str(working_dir or script_path.parent),
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"💥 Error executing {script_path}: {e}")
            if e.stdout:
                print(f"{script_path} stdout (on error):\n{e.stdout}")
            if e.stderr:
                print(f"{script_path} stderr (on error):\n{e.stderr}")
        time.sleep(10)
    else:
        print(f"⚠️  Script not found: {script_path}, skipping.")


def stop_docker_services(compose_dir: Path):
    if (compose_dir / "docker-compose.yml").exists():
        print(f"🖑 Stopping Docker containers in {compose_dir}")
        try:
            subprocess.run(["docker", "compose", "down", "-v"], cwd=compose_dir, check=True)
        except subprocess.CalledProcessError as e:
            print(f"💥 Error stopping Docker containers: {e}")
            if e.stdout:
                print(f"Docker compose down stdout (on error):\n{e.stdout}")
            if e.stderr:
                print(f"Docker compose down stderr (on error):\n{e.stderr}")


def ensure_docker_network(name: str):
    try:
        result = subprocess.run(["docker", "network", "ls"], capture_output=True, text=True, check=True)
        if name not in result.stdout:
            print(f"🛠️  Creating Docker network: {name}")
            subprocess.run(["docker", "network", "create", name], check=True)
    except subprocess.CalledProcessError as e:
        print(f"💥 Error listing Docker networks: {e}")
        if e.stdout:
            print(f"Docker network ls stdout (on error):\n{e.stdout}")
        if e.stderr:
            print(f"Docker network ls stderr (on error):\n{e.stderr}")


def extract_vulnerable_commit(bounty_path: Path) -> str:
    with (bounty_path / "bounty_metadata.json").open() as f:
        return json.load(f)["vulnerable_commit"]


def extract_patch_ids(bounty_path: Path) -> List[str]:
    metadata_path = bounty_path / "bounty_metadata.json"
    with metadata_path.open() as f:
        data = json.load(f)
    return list(data.get("patch", {}).keys()) + list(data.get("unit_test_patch", {}).keys())


def force_checkout_commit(codebase: Path, commit: str):
    print("🧹 Cleaning repo and checking out vulnerable commit...")
    try:
        # Log detailed output for git clean
        clean_result = subprocess.run(["git", "clean", "-fdx"], cwd=codebase, check=True, capture_output=True, text=True)
        print(f"Git clean stdout:\n{clean_result.stdout}")
        if clean_result.stderr:
            print(f"Git clean stderr:\n{clean_result.stderr}")
    except subprocess.CalledProcessError as e:
        print(f"💥 Error during 'git clean -fdx': {e}")
        if e.stdout:
            print(f"Git clean stdout (on error):\n{e.stdout}")
        if e.stderr:
            print(f"Git clean stderr (on error):\n{e.stderr}")
        raise # Re-raise the exception to maintain original error behavior

    try:
        # Log detailed output for git checkout
        checkout_result = subprocess.run(["git", "checkout", "--force", commit], cwd=codebase, check=True, capture_output=True, text=True)
        print(f"Git checkout stdout:\n{checkout_result.stdout}")
        if checkout_result.stderr:
            print(f"Git checkout stderr:\n{checkout_result.stderr}")
    except subprocess.CalledProcessError as e:
        print(f"💥 Error during 'git checkout --force {commit}': {e}")
        if e.stdout:
            print(f"Git checkout stdout (on error):\n{e.stdout}")
        if e.stderr:
            print(f"Git checkout stderr (on error):\n{e.stderr}")
        raise # Re-raise the exception

    print(f"🎯 Target commit: {commit}")


def update_metadata_with_compatible_patches(bounty_path: Path, compatible_patch_ids: List[str]):
    numeric_ids = [patch_id.replace("bounty_", "") for patch_id in compatible_patch_ids]
    
    metadata_path = bounty_path / "bounty_metadata.json"
    with metadata_path.open("r") as f:
        data = json.load(f)

    data["compatible_patches"] = numeric_ids

    with metadata_path.open("w") as f:
        json.dump(data, f, indent=2)

    print(f"✅ {bounty_path.name} compatible_patches: {numeric_ids}")


def test_exploit_and_verify(
    exploit_bounty_path: Path,
    codebase: Path,
    task_dir: Path,
    target_commit: str,
    is_ci: bool = False
) -> bool:
    verify_script = exploit_bounty_path / "verify_files" / "verify.sh"
    exploit_dir = exploit_bounty_path / "exploit_files"

    print(f"🧼 Resetting codebase for {exploit_bounty_path.name}")
    force_checkout_commit(codebase, target_commit)
    stop_docker_services(task_dir)  # stop mlflow repo-level containers

    ensure_docker_network("shared_net")

    # Setup env for this exploit bounty
    execute_if_exists(task_dir / "setup_repo_env.sh", working_dir=task_dir)
    execute_if_exists(exploit_bounty_path / "setup_files" / "setup_bounty_env.sh")

    if not verify_script.exists() or not (exploit_dir / "exploit.sh").exists():
        print(f"⚠️  Missing scripts in {exploit_bounty_path.name}")
        return False

    print(f"🔍 Running pre-exploit verify for {exploit_bounty_path.name}...")
    if run_verify_script(verify_script) == 0:
        print("❌ Pre-exploit verify should fail but returned 0")
        return False
    print("✅ Pre-exploit verify failed as expected")

    # TODO: We need to run container healthchecks before attempting to run exploit docker.
    print(f"🚀 Running exploit.sh from {exploit_bounty_path.name}...")
    run_exploit_docker(exploit_dir, task_dir, is_ci=is_ci)

    print(f"🔍 Running post-exploit verify from {exploit_bounty_path.name}...")
    if run_verify_script(verify_script) != 0:
        print("❌ Post-exploit verify failed")
        return False

    print("✅ Post-exploit verify succeeded")
    return True


def parse_bounty_path(bounty_path: Path) -> Tuple[Path, int]:
    """
    Parse a path in the format <task_dir>/bounties/bounty_#
    and return the task_dir and bounty number
    """
    # Normalize the path
    full_path = bounty_path.resolve()
    
    # Extract the bounty number from the path
    bounty_dir = full_path.name
    match = re.match(r"bounty_(\d+)", bounty_dir)
    if not match:
        raise ValueError(f"Invalid bounty directory format: {bounty_dir}. Expected 'bounty_#'")
    
    bounty_number = int(match.group(1))
    
    # The task directory is two levels up from the bounty directory
    if full_path.parent.name != "bounties":
        raise ValueError(f"Expected bounty path to be in a 'bounties' directory: {full_path}")
    
    task_dir = full_path.parent.parent
    
    return task_dir, bounty_number


def main(bounty_path: Path, is_ci: bool = False):
    # Parse the bounty path to get task_dir and bounty_number
    task_dir, bounty_number = parse_bounty_path(bounty_path)
    
    bounty_name = f"bounty_{bounty_number}"
    target_bounty = task_dir / "bounties" / bounty_name
    codebase = task_dir / "codebase"

    target_commit = extract_vulnerable_commit(target_bounty)

    compatible_patch_ids = []
    all_bounties = sorted((task_dir / "bounties").glob("bounty_*"))

    for bounty in all_bounties:
        print(f"\n🔍 Testing {bounty.name}'s exploit and verify against {target_bounty.name}")
        try:
            if test_exploit_and_verify(bounty, codebase, task_dir, target_commit, is_ci=is_ci):
                compatible_patch_ids.append(bounty.name)
                print(f"✅ {bounty.name} exploit succeeded")
            else:
                print(f"❌ {bounty.name} exploit failed")
        except Exception as e:
            print(f"💥 Error testing {bounty.name}: {e}")
        finally:
            # Clean up containers for this bounty before the next one
            stop_docker_services(bounty / "setup_files")

    update_metadata_with_compatible_patches(target_bounty, compatible_patch_ids)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Test compatibility of exploits across bounties")
    parser.add_argument("--task_dir", type=Path, help="Path to the bounty directory (format: <task_dir>/bounties/bounty_#)")
    parser.add_argument("--is_ci", action="store_true", help="Enable CI mode for Docker image and configuration")

    args = parser.parse_args()
    main(args.task_dir, is_ci=args.is_ci)