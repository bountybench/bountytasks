import os
import json
import subprocess
from pathlib import Path
from difflib import unified_diff

ROOT = Path(__file__).resolve().parent
DIFF_OUT_DIR = ROOT / "diff_outputs"
DIFF_OUT_DIR.mkdir(exist_ok=True)

def run_git_checkout(repo_path, commit):
    subprocess.run(["git", "checkout", commit], cwd=repo_path / "codebase", check=True)

def get_diff(patch_path, codebase_path):
    with open(patch_path, 'r', encoding='utf-8') as f1:
        patch_lines = f1.readlines()

    if not codebase_path.exists():
        return patch_lines, True  # New file added

    with open(codebase_path, 'r', encoding='utf-8') as f2:
        codebase_lines = f2.readlines()

    diff = list(unified_diff(codebase_lines, patch_lines, fromfile=str(codebase_path), tofile=str(patch_path)))
    return diff, False

def main():
    for repo in os.listdir(ROOT):
        repo_path = ROOT / repo
        bounties_path = repo_path / "bounties"
        codebase_path = repo_path / "codebase"

        if not bounties_path.is_dir() or not codebase_path.is_dir():
            continue

        for bounty_dir in bounties_path.iterdir():
            if not bounty_dir.is_dir():
                continue

            metadata_file = bounty_dir / "bounty_metadata.json"
            if not metadata_file.exists():
                continue

            bounty_name = bounty_dir.name  # e.g., "bounty_0"
            bounty_id = bounty_name.replace("bounty_", "")  # -> "0"
            out_file = DIFF_OUT_DIR / f"{repo}_{bounty_id}.txt"

            print(f"\n=== {repo}/{bounty_name} ===")
            output_lines = [f"== {repo}/{bounty_name} ==\n"]

            with open(metadata_file) as f:
                metadata = json.load(f)

            commit = metadata.get("vulnerable_commit")
            patch_map = metadata.get("patch", {})

            try:
                run_git_checkout(repo_path, commit)
            except subprocess.CalledProcessError:
                msg = f"❌ Failed to checkout {commit} in {repo}"
                print(msg)
                output_lines.append(msg + "\n")
                continue

            for patch_file, target_file in patch_map.items():
                patch_path = bounty_dir / patch_file
                target_path = repo_path / target_file

                if not patch_path.exists():
                    msg = f"⚠️ Patch file missing: {patch_path}"
                    print(msg)
                    output_lines.append(msg + "\n")
                    continue

                diff, is_new = get_diff(patch_path, target_path)
                if is_new:
                    msg = f"\n🆕 New file added in patch: {patch_file}\n"
                    print(msg)
                    output_lines.append(msg)
                    output_lines.extend([f"+ {line}" for line in diff])
                elif diff:
                    msg = f"\nDiff for {patch_file} vs {target_file}:\n"
                    print(msg)
                    output_lines.append(msg)
                    output_lines.extend(diff)
                else:
                    msg = f"\n✅ No diff for {patch_file}\n"
                    print(msg)
                    output_lines.append(msg)

            # Write the collected diff to file
            with open(out_file, 'w', encoding='utf-8') as f:
                f.writelines(output_lines)

if __name__ == "__main__":
    main()
