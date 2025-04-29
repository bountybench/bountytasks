#!/usr/bin/env python3
import os
import json
from pathlib import Path

def count_bounties(root_dir):
    total_bounties = 0
    bounties_with_patches = []
    bounties_with_invariants = []
    bounties_no_patch = []
    missing_repo_invariants = []
    missing_bounty_invariants = []
    invariant_violations = []
    folder_counts = {}
    repos = set()  # Track unique repositories
    
    for root, _, files in os.walk(root_dir):
        if 'bounty_metadata.json' in files:
            total_bounties += 1
            metadata_path = Path(root) / 'bounty_metadata.json'
            
            try:
                with open(metadata_path, 'r') as f:
                    data = json.load(f)

                    patch_data = data.get('patch')
                    
                    # Restored original validation with path tracking
                    if not patch_data or (isinstance(patch_data, str) and not patch_data.strip()):
                        bounties_no_patch.append(str(metadata_path))
                    else:
                        bounties_with_patches.append(str(metadata_path))

                    repo_metadata_path = metadata_path.parent.parent.parent / 'metadata.json'
                        
                    repo_missing = not check_repo_invariants(repo_metadata_path, str(metadata_path), missing_repo_invariants)
                    
                    if not repo_missing:
                        if 'invariant_thresholds' not in data:
                            missing_bounty_invariants.append(str(metadata_path))
                        else:
                            # Check if the invariant thresholds are empty
                            bounty_invariants = data.get('invariant_thresholds', {})
                            
                            # Read repo metadata to check if both are empty
                            with open(repo_metadata_path, 'r') as repo_f:
                                repo_metadata = json.load(repo_f)
                                repo_invariants = repo_metadata.get('invariant_thresholds', {})
                                
                                if not repo_invariants and not bounty_invariants:
                                    missing_bounty_invariants.append(str(metadata_path))
                                else:
                                    bounties_with_invariants.append(str(metadata_path))
                                    check_invariant_violations(data, repo_metadata_path, metadata_path, invariant_violations, missing_bounty_invariants)

            except (json.JSONDecodeError, IOError) as e:
                print(f"Error processing {metadata_path}: {e}")

            base_folder = metadata_path.parent.parent.parent.name
            folder_counts[base_folder] = folder_counts.get(base_folder, 0) + 1
            repos.add(base_folder)  # Add repository to the set of unique repos

    return (total_bounties, bounties_with_patches, bounties_with_invariants,
            bounties_no_patch, missing_repo_invariants, 
            missing_bounty_invariants, invariant_violations, folder_counts,
            len(repos))  # Return the count of unique repositories

def check_repo_invariants(repo_metadata_path, bounty_path, missing_repo_invariants):
    if not repo_metadata_path.exists():
        missing_repo_invariants.append(bounty_path)
        return False
    try:
        with open(repo_metadata_path, 'r') as repo_f:
            if 'invariant_thresholds' not in json.load(repo_f):
                missing_repo_invariants.append(bounty_path)
                return False
    except Exception as e:
        print(f"Error checking repo invariants: {e}")
        missing_repo_invariants.append(bounty_path)
        return False
    return True

def check_invariant_violations(data, repo_metadata_path, metadata_path, invariant_violations, missing_bounty_invariants=None):
    try:
        with open(repo_metadata_path, 'r') as repo_f:
            repo_metadata = json.load(repo_f)
            repo_invariants = repo_metadata.get('invariant_thresholds', {})
            bounty_invariants = data.get('invariant_thresholds', {})
            
            # Check if both dictionaries are empty
            if missing_bounty_invariants is not None and not repo_invariants and not bounty_invariants:
                missing_bounty_invariants.append(str(metadata_path))
                
            combined_invariants = {**repo_invariants, **bounty_invariants}
            
            for key, threshold in combined_invariants.items():
                actual_value = data.get(key, 0)
                if actual_value < threshold:
                    invariant_violations.append({
                        'path': str(metadata_path),
                        'metric': key,
                        'threshold': threshold,
                        'actual': actual_value
                    })
    except Exception as e:
        print(f"Error checking invariants for {metadata_path}: {e}")

def check_docker_health_checks(root_dir):
    missing_health_checks = []
    repo_compose_files = {}
    repo_has_health_check = {}
    
    # Find all repos (directories with 'bounties' subdirectory)
    repo_dirs = []
    for item in os.listdir(root_dir):
        item_path = os.path.join(root_dir, item)
        if os.path.isdir(item_path) and 'bounties' in os.listdir(item_path):
            repo_dirs.append(item_path)
    
    # Check repo-level docker-compose files
    for repo_dir in repo_dirs:
        repo_name = os.path.basename(repo_dir)
        compose_path = os.path.join(repo_dir, 'docker-compose.yml')
        
        if os.path.exists(compose_path):
            try:
                with open(compose_path, 'r') as f:
                    content = f.read()
                    if 'healthcheck:' in content:
                        repo_has_health_check[repo_name] = True
                    else:
                        repo_has_health_check[repo_name] = False
                        missing_health_checks.append(compose_path)
            except Exception as e:
                print(f"Error checking {compose_path}: {e}")
                missing_health_checks.append(compose_path)
        else:
            # Check first bounty docker-compose if no repo-level file
            bounty_compose_found = False
            for root, _, files in os.walk(os.path.join(repo_dir, 'bounties')):
                if 'docker-compose.yml' in files:
                    bounty_compose_path = os.path.join(root, 'docker-compose.yml')
                    bounty_compose_found = True
                    try:
                        with open(bounty_compose_path, 'r') as f:
                            content = f.read()
                            if 'healthcheck:' not in content:
                                missing_health_checks.append(bounty_compose_path)
                    except Exception as e:
                        print(f"Error checking {bounty_compose_path}: {e}")
                        missing_health_checks.append(bounty_compose_path)
                    break  # Only check the first bounty compose file
            
    return missing_health_checks

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Count bounty metadata files')
    parser.add_argument('root_dir', nargs='?', default=os.getcwd(),
                       help='Root directory to search from (defaults to current working directory)')
    args = parser.parse_args()
    
    (total, bounties_with_patches, bounties_with_invariants, 
     bounties_no_patch, missing_repo_invariants, 
     missing_bounty_invariants, invariant_violations, 
     folder_counts, repo_count) = count_bounties(args.root_dir)

    print("\n\033[1mBounty Statistics Report\033[0m")
    print("=" * 30)
    print(f"\033[1;34m• Total Repositories:\033[0m \033[1;32m{repo_count}\033[0m")
    print(f"\033[1;34m• Total Bounties:\033[0m {total}")
    print(f"\033[1;34m• Bounties With Patches:\033[0m \033[1;32m{len(bounties_with_patches)}\033[0m")
    print(f"\033[1;34m• Bounties With Invariant Thresholds:\033[0m \033[1;32m{len(bounties_with_invariants)}\033[0m")
    
    print("\n\033[1mDistribution by Project\033[0m")
    print("=" * 30)
    max_length = max(len(folder) for folder in folder_counts)
    for folder, count in sorted(folder_counts.items()):
        print(f"\033[1;32m{folder.ljust(max_length)}\033[0m │ \033[1;36m{count}\033[0m")

    print(f"\n\033[1;34m• Bounties With Patches:\033[0m \033[1;31m{len(bounties_with_patches)}\033[0m")
    for path in bounties_with_patches:
        print(path)
    
    print(f"\n\033[1;34m• Bounties With Invariants:\033[0m \033[1;31m{len(bounties_with_invariants)}\033[0m")
    for path in bounties_with_invariants:
        print(path)

    print("\n\033[1mNegatives Report\033[0m")
    print("=" * 30)
    print(f"\033[1;34m• Bounties Without Patches:\033[0m \033[1;31m{len(bounties_no_patch)}\033[0m")
    for path in bounties_no_patch:
        print(path)

    print(f"\033[1;34m• Missing Invariants:\033[0m \033[1;31m{len(missing_repo_invariants) + len(missing_bounty_invariants)}\033[0m")
    for path in missing_repo_invariants:
        print(f"  \033[33m{path}\033[0m")
    for path in missing_bounty_invariants:
        print(f"  \033[33m{path}\033[0m")

            
    missing_health_checks = check_docker_health_checks(args.root_dir)
    print("\n\033[1mDocker Health Check Report\033[0m")
    print("=" * 30)
    if missing_health_checks:
        print(f"\033[1;34m• Docker Compose Files Missing Health Checks:\033[0m \033[1;31m{len(missing_health_checks)}\033[0m")
        for path in missing_health_checks:
            print(f"  \033[31m{os.path.relpath(path, args.root_dir)}\033[0m")
    else:
        print(f"\033[1;34m• Docker Compose Files Missing Health Checks:\033[0m \033[1;32m0\033[0m")