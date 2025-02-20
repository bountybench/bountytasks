#!/usr/bin/env python3
import os
import json
from pathlib import Path

def count_bounties(root_dir):
    total_bounties = 0
    no_patch_count = 0
    folder_counts = {}
    no_patch_paths = []
    missing_repo_invariants = []  # Repos missing invariant_thresholds
    missing_bounty_invariants = []  # Bounties missing invariant_thresholds
    invariant_violations = []
    
    for root, dirs, files in os.walk(root_dir):
        if 'bounty_metadata.json' in files:
            total_bounties += 1
            metadata_path = Path(root) / 'bounty_metadata.json'
            
            try:
                with open(metadata_path, 'r') as f:
                    data = json.load(f)
                    
                    patch_data = data.get('patch')
                    
                    # Restored original validation with path tracking
                    if not patch_data or (isinstance(patch_data, str) and not patch_data.strip()):
                        no_patch_count += 1
                        no_patch_paths.append(str(metadata_path))
                    
                    # New invariant checks
                    repo_metadata_path = metadata_path.parent.parent.parent / 'metadata.json'
                    
                    # Check repo-level existence and field
                    repo_missing = False
                    if not repo_metadata_path.exists():
                        missing_repo_invariants.append(str(metadata_path))
                        repo_missing = True
                    else:
                        try:
                            with open(repo_metadata_path, 'r') as repo_f:
                                if 'invariant_thresholds' not in json.load(repo_f):
                                    missing_repo_invariants.append(str(metadata_path))
                                    repo_missing = True
                        except Exception as e:
                            print(f"Error checking repo invariants: {e}")
                            missing_repo_invariants.append(str(metadata_path))
                            repo_missing = True
                    
                    # Check bounty-level if repo valid
                    if not repo_missing:
                        if 'invariant_thresholds' not in data:
                            missing_bounty_invariants.append(str(metadata_path))
                        else:
                            repo_metadata_path = metadata_path.parent.parent.parent / 'metadata.json'
                            try:
                                with open(repo_metadata_path, 'r') as repo_f:
                                    repo_metadata = json.load(repo_f)
                                    
                                    if 'invariant_thresholds' not in repo_metadata:
                                        invariant_violations.append({
                                            'path': str(metadata_path),
                                            'metric': 'repo_invariant_thresholds',
                                            'threshold': 'required',
                                            'actual': 'missing'
                                        })
                                    else:
                                        repo_invariants = repo_metadata['invariant_thresholds']
                                        bounty_invariants = data.get('invariant_thresholds', {})
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
            except (json.JSONDecodeError, IOError) as e:
                print(f"Error processing {metadata_path}: {e}")
            
            # Extract base folder name
            try:
                base_folder = metadata_path.parent.parent.parent.name
            except IndexError:
                base_folder = os.path.basename(root)
            
            folder_counts[base_folder] = folder_counts.get(base_folder, 0) + 1
    
    return total_bounties, no_patch_count, folder_counts, no_patch_paths, missing_repo_invariants, missing_bounty_invariants, invariant_violations

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Count bounty metadata files')
    parser.add_argument('root_dir', help='Root directory to search from')
    args = parser.parse_args()
    
    total, no_patch, folder_counts, no_patch_paths, missing_repo_invariants, missing_bounty_invariants, invariant_violations = count_bounties(args.root_dir)
    
    print("\n\033[1mBounty Statistics Report\033[0m")
    print("=" * 30)
    print(f"\033[1;34m• Total Bounties:\033[0m {total}")
    print(f"\033[1;34m• Bounties Without Patches:\033[0m \033[1;31m{no_patch}\033[0m")
    print(f"\033[1;34m• Bounties Missing Invariants:\033[0m \033[1;31m{len(missing_repo_invariants) + len(missing_bounty_invariants)}\033[0m")
    
    print("\n\033[1mDistribution by Project\033[0m")
    print("=" * 30)
    max_length = max(len(folder) for folder in folder_counts)
    for folder, count in sorted(folder_counts.items()):
        print(f"\033[1;32m{folder.ljust(max_length)}\033[0m │ \033[1;36m{count}\033[0m")
    
    print("\n\033[1mBounties Without Patches:\033[0m")
    print("=" * 30)
    for path in no_patch_paths:
        print(path)
    
    print("\n\033[1mMissing Invariants:\033[0m")
    print("=" * 30)
    for path in missing_repo_invariants:
        print(f"  \033[33m{path}\033[0m")