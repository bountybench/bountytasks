#!/usr/bin/env python3
import os
import json
import glob
import re
from pathlib import Path

def parse_bounty_value(value):
    """
    Parse bounty value from various formats.
    
    Args:
        value: The bounty value string or number
        
    Returns:
        float: The parsed bounty value
    """
    if value is None or value == "":
        return 0.0
    
    # If already a number, return it
    if isinstance(value, (int, float)):
        return float(value)
    
    # Remove dollar sign if present
    if isinstance(value, str) and value.startswith('$'):
        value = value[1:]
    
    # Handle range format (e.g., "750 to 900")
    if isinstance(value, str) and ' to ' in value:
        parts = value.split(' to ')
        if len(parts) == 2:
            try:
                # Use the average of the range
                return (float(parts[0]) + float(parts[1])) / 2
            except ValueError:
                pass
    
    # Try to convert to float
    try:
        return float(value)
    except (ValueError, TypeError):
        print(f"Warning: Could not parse bounty value: {value}, using 0.0")
        return 0.0

def calculate_bounties(root_dir, verbose=False, detailed=False):
    """
    Calculate the total disclosure and patch bounties from all bounty_metadata.json files.
    
    Args:
        root_dir: Root directory to search from
        verbose: Whether to print detailed information for each bounty
        detailed: Whether to print a summary table of all bounties at the end
        
    Returns:
        tuple: (total_disclosure_bounty, total_patch_bounty, bounty_count, errors, bounty_details)
    """
    total_disclosure_bounty = 0.0
    total_patch_bounty = 0.0
    bounty_count = 0
    errors = []
    bounty_details = []
    
    # Find all bounty_metadata.json files directly
    pattern = os.path.join(root_dir, "**/bounty_*/bounty_metadata.json")
    metadata_files = glob.glob(pattern, recursive=True)
    
    # Process each file
    for metadata_path in metadata_files:
        try:
            with open(metadata_path, 'r') as f:
                data = json.load(f)
                
                # Extract and parse bounty values
                disclosure_bounty = parse_bounty_value(data.get('disclosure_bounty'))
                
                # Check for both patch_bounty and fix_bounty (some files use fix_bounty)
                patch_bounty = parse_bounty_value(data.get('patch_bounty'))
                fix_bounty = parse_bounty_value(data.get('fix_bounty'))
                total_patch = patch_bounty + fix_bounty
                
                # Extract bounty name from path
                bounty_path = os.path.dirname(metadata_path)
                bounty_name = os.path.basename(bounty_path)
                project_path = os.path.dirname(os.path.dirname(bounty_path))
                project_name = os.path.basename(project_path)
                
                # Add to totals
                total_disclosure_bounty += disclosure_bounty
                total_patch_bounty += total_patch
                bounty_count += 1
                
                # Store bounty details for later display
                bounty_details.append({
                    'project': project_name,
                    'bounty': bounty_name,
                    'path': metadata_path,
                    'disclosure_bounty': disclosure_bounty,
                    'patch_bounty': patch_bounty,
                    'fix_bounty': fix_bounty,
                    'total': disclosure_bounty + total_patch
                })
                
                # Print individual bounty details if verbose
                if verbose:
                    print(f"File: {metadata_path}")
                    print(f"  Disclosure Bounty: ${disclosure_bounty:.2f}")
                    if patch_bounty > 0:
                        print(f"  Patch Bounty: ${patch_bounty:.2f}")
                    if fix_bounty > 0:
                        print(f"  Fix Bounty: ${fix_bounty:.2f}")
                    print(f"  Total: ${disclosure_bounty + total_patch:.2f}")
                    print("-" * 50)
                
        except (json.JSONDecodeError, IOError) as e:
            error_msg = f"Error processing {metadata_path}: {e}"
            print(error_msg)
            errors.append(error_msg)
    
    return total_disclosure_bounty, total_patch_bounty, bounty_count, errors, bounty_details

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Calculate total bounty values')
    parser.add_argument('root_dir', nargs='?', default=os.getcwd(), 
                        help='Root directory to search from (default: current directory)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Show detailed information for each bounty')
    parser.add_argument('--detailed', '-d', action='store_true',
                        help='Show a summary table of all bounties')
    args = parser.parse_args()
    
    total_disclosure, total_patch, count, errors, bounty_details = calculate_bounties(
        args.root_dir, args.verbose, args.detailed)
    
    print("\n" + "=" * 50)
    print(f"SUMMARY (Total of {count} bounties)")
    print("=" * 50)
    print(f"Total Disclosure Bounty: ${total_disclosure:.2f}")
    print(f"Total Patch Bounty: ${total_patch:.2f}")
    print(f"Grand Total: ${(total_disclosure + total_patch):.2f}")
    print("=" * 50)
    
    # Print detailed table of all bounties
    if bounty_details:
        print("\n" + "=" * 100)
        print("DETAILED BOUNTY BREAKDOWN")
        print("=" * 100)
        print(f"{'PROJECT':<20} {'BOUNTY':<15} {'DISCLOSURE ($)':<15} {'PATCH ($)':<15} {'FIX ($)':<15} {'TOTAL ($)':<15}")
        print("-" * 100)
        
        # Sort by total bounty value (highest first)
        sorted_bounties = sorted(bounty_details, key=lambda x: x['total'], reverse=True)
        
        for bounty in sorted_bounties:
            print(f"{bounty['project']:<20} {bounty['bounty']:<15} {bounty['disclosure_bounty']:<15.2f} "
                  f"{bounty['patch_bounty']:<15.2f} {bounty['fix_bounty']:<15.2f} {bounty['total']:<15.2f}")
        
        print("=" * 100)
    
    if errors:
        print(f"\nEncountered {len(errors)} errors during processing.")

if __name__ == '__main__':
    main()
