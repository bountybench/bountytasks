#!/usr/bin/env python3
import argparse
import sys
import os
import subprocess
import time

def get_commits(repo_path, start_commit, end_commit):
    try:
        cmd = [
            'git',
            '-C',
            repo_path,
            'rev-list',
            '--reverse',
            f'{start_commit}^..{end_commit}'
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        commits = result.stdout.strip().split('\n')
        print(f"Retrieved {len(commits)} commits from {start_commit} to {end_commit}.")
        return commits
    except subprocess.CalledProcessError as e:
        print(f"Error retrieving commits: {e.stderr}")
        return []


def verify_exploit(commit_id):
    try:
        project_root = os.path.dirname(os.path.abspath(__file__))

        setup_files_dir = os.path.join(project_root, 'setup_files')
        setup_script = os.path.join(setup_files_dir, 'setup_bounty_env.sh')
        if not os.path.isfile(setup_script):
            print(f"Setup script not found: {setup_script}")
            return False

        print(f"Running setup script for commit {commit_id}...")
        subprocess.run(['./setup_bounty_env.sh', commit_id], cwd=setup_files_dir, check=True)

        print("Waiting for 30s to allow environment setup...")
        time.sleep(30)  

        exploit_files_dir = os.path.join(project_root, 'exploit_files')
        exploit_script = os.path.join(exploit_files_dir, 'exploit.sh')
        if not os.path.isfile(exploit_script):
            print(f"Exploit script not found: {exploit_script}")
            return False

        print("Running exploit script...")
        subprocess.run(['./exploit.sh'], cwd=exploit_files_dir, check=True)

        verify_script = os.path.join(project_root, 'verify.sh')
        if not os.path.isfile(verify_script):
            print(f"Verify script not found: {verify_script}")
            return False

        print("Running verify script...")
        result = subprocess.run(['./verify.sh'], cwd=project_root)

        if result.returncode == 0:
            print(f"Verification successful for commit {commit_id}.")
            return True
        else:
            print(f"Verification failed for commit {commit_id}.")
            return False

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while executing a script: {e}")
        return False
    except Exception as e:
        print(f"Unexpected error during verification: {e}")
        return False


def find_latest_true_commit(commits):
    left = 0
    right = len(commits) - 1
    latest_true = None

    while left <= right:
        mid = (left + right) // 2
        mid_commit = commits[mid]
        print(f"\nChecking commit {mid_commit} (Index {mid})...")

        if verify_exploit(mid_commit):
            latest_true = mid_commit
            print(f"Commit {mid_commit} returned True. Searching higher commits...")
            left = mid + 1 
        else:
            print(f"Commit {mid_commit} returned False. Searching lower commits...")
            right = mid - 1  

    return latest_true


def main():
    parser = argparse.ArgumentParser(description="Binary search through Git commits to find the latest commit that returns True.")
    parser.add_argument(
        '--repo-path',
        type=str,
        required=True,
        help='Path to the Git repository (e.g., /path/to/repo)'
    )
    parser.add_argument(
        '--start-commit',
        type=str,
        required=False,
        help='Starting commit ID (exclusive). If not provided, the initial commit is used.'
    )
    parser.add_argument(
        '--end-commit',
        type=str,
        required=False,
        default='HEAD',
        help='Ending commit ID (inclusive). Defaults to HEAD.'
    )
    args = parser.parse_args()

    repo_path = os.path.abspath(args.repo_path)
    start_commit = args.start_commit
    end_commit = args.end_commit


    if not os.path.isdir(repo_path):
        print(f"Error: Repository path '{repo_path}' does not exist or is not a directory.")
        sys.exit(1)

    # If start_commit is not provided, retrieve the initial commit
    if not start_commit:
        try:
            initial_commit_cmd = [
                'git',
                '-C',
                repo_path,
                'rev-list',
                '--max-parents=0',
                'HEAD'
            ]
            initial_commit = subprocess.run(initial_commit_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True).stdout.strip()
            start_commit = initial_commit
            print(f"Using initial commit as start_commit: {start_commit}")
        except subprocess.CalledProcessError as e:
            print(f"Error retrieving initial commit: {e.stderr}")
            sys.exit(1)
    commits = get_commits(repo_path, start_commit, end_commit)
    if not commits:
        print("No commits found in the specified range.")
        sys.exit(1)


    print("Starting binary search to find the latest commit that returns True...")
    latest_true_commit = find_latest_true_commit(commits)

    if latest_true_commit:
        print(f"\nLatest commit that returns True: {latest_true_commit}")
    else:
        print(f'no commit found')


if __name__ == "__main__":
    main()
