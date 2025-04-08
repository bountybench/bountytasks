import subprocess
import json
import time
import os
from pathlib import Path
from typing import List


def run_verify_script(verify_script: Path) -> int:
    result = subprocess.run(
        ["bash", str(verify_script.name)],
        cwd=str(verify_script.parent),
        capture_output=True,
        text=True
    )
    print(f"\n🔎 verify.sh stdout:\n{result.stdout.strip()}")
    print(f"🛑 verify.sh stderr:\n{result.stderr.strip()}")
    return result.returncode


def run_exploit_docker(exploit_dir: Path, task_dir: Path, image="cybench/bountyagent:latest", network="shared_net") -> int:
    relative_path = exploit_dir.relative_to(task_dir)

    env_args = []
    if "OPENAI_API_KEY" in os.environ:
        env_args = ["-e", f"OPENAI_API_KEY={os.environ['OPENAI_API_KEY']}"]

    cmd = [
        "docker", "run",
        "--rm",
        "--privileged",
        "--network", network,
        "--cgroupns", "host",
        *env_args,
        "-v", f"{task_dir}:/app",
        image,
        "/bin/bash", "-c",
        f"cd '/app/{relative_path}' && bash exploit.sh true"
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    print(result.stderr)
    return result.returncode


def execute_if_exists(script_path: Path, working_dir: Path = None):
    if script_path.exists():
        print(f"⚙️  Executing: {script_path}")
        subprocess.run(
            ["bash", str(script_path)],
            cwd=str(working_dir or script_path.parent),
            check=True
        )
        time.sleep(10)
    else:
        print(f"⚠️  Script not found: {script_path}, skipping.")


def stop_docker_services(compose_dir: Path):
    if (compose_dir / "docker-compose.yml").exists():
        print(f"🛑 Stopping Docker containers in {compose_dir}")
        subprocess.run(["docker", "compose", "down", "-v"], cwd=compose_dir)


def ensure_docker_network(name: str):
    result = subprocess.run(["docker", "network", "ls"], capture_output=True, text=True)
    if name not in result.stdout:
        print(f"🛠️  Creating Docker network: {name}")
        subprocess.run(["docker", "network", "create", name], check=True)


def extract_vulnerable_commit(bounty_path: Path) -> str:
    with (bounty_path / "bounty_metadata.json").open() as f:
        return json.load(f)["vulnerable_commit"]


def clean_repo_state(codebase: Path, commit: str):
    print("🧹 Cleaning repo and checking out vulnerable commit...")
    subprocess.run(["git", "clean", "-fdx"], cwd=codebase, check=True)
    subprocess.run(["git", "checkout", "--force", commit], cwd=codebase, check=True)


def extract_patch_ids(bounty_path: Path) -> List[str]:
    metadata_path = bounty_path / "bounty_metadata.json"
    with metadata_path.open() as f:
        data = json.load(f)

    patch_ids = list(data.get("patch", {}).keys())
    patch_ids += list(data.get("unit_test_patch", {}).keys())
    return patch_ids


def update_metadata_with_compatible_patches(bounty_path: Path, compatible_patch_ids: List[str]):
    metadata_path = bounty_path / "bounty_metadata.json"
    with metadata_path.open("r") as f:
        data = json.load(f)

    data["compatible_patches"] = compatible_patch_ids

    with metadata_path.open("w") as f:
        json.dump(data, f, indent=2)

    print(f"✅ {bounty_path.name} compatible_patches: {compatible_patch_ids}")


def test_exploit_against_target(bounty_path: Path, verify_script: Path, codebase: Path, task_dir: Path) -> bool:
    exploit_dir = bounty_path / "exploit_files"
    if not verify_script.exists() or not (exploit_dir / "exploit.sh").exists():
        print(f"⚠️  Missing scripts in {bounty_path.name}")
        return False

    print(f"🔍 Running pre-exploit verify for {bounty_path.name}...")
    if run_verify_script(verify_script) == 0:
        print("❌ Pre-exploit verify should fail but returned 0")
        return False
    print("✅ Pre-exploit verify failed as expected")

    print(f"🚀 Running exploit.sh for {bounty_path.name}...")
    if run_exploit_docker(exploit_dir, task_dir) != 0:
        print("❌ Exploit.sh failed to run successfully")
        return False

    print(f"🔍 Running post-exploit verify for {bounty_path.name}...")
    if run_verify_script(verify_script) != 0:
        print("❌ Post-exploit verify failed. Exploit likely ineffective.")
        return False

    print("✅ Post-exploit verify succeeded. Exploit worked!")
    return True


def main(task_dir: Path, bounty_number: int):
    bounty_name = f"bounty_{bounty_number}"
    bounty_0 = task_dir / "bounties" / bounty_name
    codebase = task_dir / "codebase"

    commit = extract_vulnerable_commit(bounty_0)

    # 🧼 Clean state before anything runs
    clean_repo_state(codebase, commit)
    stop_docker_services(task_dir)
    stop_docker_services(bounty_0 / "setup_files")

    ensure_docker_network("shared_net")

    execute_if_exists(task_dir / "setup_repo_env.sh", working_dir=task_dir)
    execute_if_exists(bounty_0 / "setup_files" / "setup_bounty_env.sh")

    all_bounties = sorted((task_dir / "bounties").glob("bounty_*"))
    verify_script = bounty_0 / "verify.sh"
    compatible_patch_ids = []

    for bounty in all_bounties:
        print(f"\n🔍 Testing {bounty.name}")
        try:
            if test_exploit_against_target(bounty, verify_script, codebase, task_dir):
                patch_ids = extract_patch_ids(bounty)
                compatible_patch_ids.extend(patch_ids)
                print(f"✅ {bounty.name} exploit succeeded")
            else:
                print(f"❌ {bounty.name} exploit failed")
        except Exception as e:
            print(f"💥 Error testing {bounty.name}: {e}")

    update_metadata_with_compatible_patches(bounty_0, compatible_patch_ids)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--task_dir", type=Path, required=True)
    parser.add_argument("--bounty", type=int, required=True)
    args = parser.parse_args()

    main(args.task_dir.resolve(), args.bounty)
