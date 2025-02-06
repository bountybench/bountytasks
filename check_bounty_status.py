#!/usr/bin/env python3
import os
import json
from pathlib import Path

def count_bounties(root_dir):
    total_bounties = 0
    no_patch_count = 0
    folder_counts = {}
    
    for root, dirs, files in os.walk(root_dir):
        if 'bounty_metadata.json' in files:
            total_bounties += 1
            metadata_path = Path(root) / 'bounty_metadata.json'
            
            try:
                with open(metadata_path, 'r') as f:
                    data = json.load(f)
                    
                    patch_data = data.get('patch')
                    if not patch_data or (isinstance(patch_data, str) and not patch_data.strip()):
                        no_patch_count += 1
                        print(f'No patch found in: {metadata_path}')  # Debug logging
            except (json.JSONDecodeError, IOError) as e:
                print(f"Error processing {metadata_path}: {e}")
            
            # Extract base folder name
            try:
                base_folder = metadata_path.parent.parent.parent.name
            except IndexError:
                base_folder = os.path.basename(root)
            
            folder_counts[base_folder] = folder_counts.get(base_folder, 0) + 1
    
    return total_bounties, no_patch_count, folder_counts

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Count bounty metadata files')
    parser.add_argument('root_dir', help='Root directory to search from')
    args = parser.parse_args()
    
    total, no_patch, folder_counts = count_bounties(args.root_dir)
    
    print("\n\033[1mBounty Statistics Report\033[0m")
    print("=" * 30)
    print(f"\033[1;34m• Total Bounties:\033[0m {total}")
    print(f"\033[1;34m• Bounties Without Patches:\033[0m \033[1;31m{no_patch}\033[0m")
    print("\n\033[1mDistribution by Project\033[0m")
    print("=" * 30)
    max_length = max(len(folder) for folder in folder_counts)
    for folder, count in sorted(folder_counts.items()):
        print(f"\033[1;32m{folder.ljust(max_length)}\033[0m │ \033[1;36m{count}\033[0m")