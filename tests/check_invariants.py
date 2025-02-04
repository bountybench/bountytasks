import json
import sys

def load_json(file_path):
    try:
        with open(file_path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error loading {file_path}: {str(e)}")
        sys.exit(1)

def merge_thresholds(repo_meta, bounty_meta):
    if 'invariant_thresholds' not in repo_meta:
        print("Missing invariant_thresholds key in repo meta")
        sys.exit(1)
    if 'invariant_thresholds' not in bounty_meta:
        print("Missing invariant_thresholds key in bounty meta")
        sys.exit(1)
    thresholds = repo_meta.get('invariant_thresholds', {})
    thresholds.update(bounty_meta.get('invariant_thresholds', {}))
    return thresholds

def validate_scores(thresholds, scores):
    errors = []
    for check, score in scores['invariant_scores'].items():
        if check not in thresholds:
            errors.append(f"Unknown check: {check}")
            continue
        threshold = thresholds[check]
        if not isinstance(threshold, int):
            errors.append(f"Threshold for {check} must be an integer")
            continue

        if not isinstance(score, int):
            errors.append(f"Score for {check} must be an integer")
        elif score < threshold:
            errors.append(f"{check} score {score} is below threshold {threshold}")
    return errors

def main():
    if len(sys.argv) != 5:
        print("Usage: python check_invariants.py <repo_meta> <repo_scores> <bounty_meta> <bounty_scores>")
        sys.exit(2)

    repo_meta = load_json(sys.argv[1])
    repo_scores = load_json(sys.argv[2])
    if 'invariant_scores' not in repo_scores:
        print("No invariant_scores key found in repo scores")
        sys.exit(1)
    bounty_meta = load_json(sys.argv[3])
    bounty_scores = load_json(sys.argv[4])
    if 'invariant_scores' not in bounty_scores:
        print("No invariant_scores key found in bounty scores")
        sys.exit(1)

    thresholds = merge_thresholds(repo_meta, bounty_meta)
    repo_violations = validate_scores(thresholds, repo_scores)
    bounty_violations = validate_scores(thresholds, bounty_scores)

    if repo_violations:
        print("\nRepo-level invariant violations:\n" + "\n".join(repo_violations))
    
    if bounty_violations:
        print("\nBounty-level invariant violations:\n" + "\n".join(bounty_violations))

    if repo_violations or bounty_violations:
        sys.exit(1)
    
    print("All invariants satisfied!")
    sys.exit(0)

if __name__ == "__main__":
    main()