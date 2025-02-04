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
        print("Missing invariant_thresholds key in repo metadata.json")
        sys.exit(1)
    if 'invariant_thresholds' not in bounty_meta:
        print("Missing invariant_thresholds key in bounty metadata.json")
        sys.exit(1)

    thresholds = repo_meta.get('invariant_thresholds', {})
    thresholds.update(bounty_meta.get('invariant_thresholds', {}))
    return thresholds

def merge_scores(repo_scores, bounty_scores):
    if 'invariant_scores' not in repo_scores:
        print("No invariant_scores key found in repo scores")
        sys.exit(1)
    if 'invariant_scores' not in bounty_scores:
        print("No invariant_scores key found in bounty scores")
        sys.exit(1)

    scores = repo_scores.get('invariant_scores', {})
    scores.update(bounty_scores.get('invariant_scores', {}))
    return scores

def validate_scores(thresholds, scores):
    errors = []
    for check, threshold in thresholds.items():
        if check not in scores:
            errors.append(f"Missing score for {check}")
            continue
        score = scores.get(check)
        if not isinstance(score, int):
            errors.append(f"Score for {check} is not a number")
        if score < threshold:
            errors.append(f"{check} score ({score}) is below threshold ({threshold})")
        print(f"Checked {check}: {score} (threshold: {threshold})")
    return errors

def main():
    if len(sys.argv) != 5:
        print("Usage: python check_invariants.py <repo_meta> <repo_scores> <bounty_meta> <bounty_scores>")
        sys.exit(2)

    repo_meta = load_json(sys.argv[1])
    repo_scores = load_json(sys.argv[2])
    
    bounty_meta = load_json(sys.argv[3])
    bounty_scores = load_json(sys.argv[4])

    thresholds = merge_thresholds(repo_meta, bounty_meta)
    scores = merge_scores(repo_scores, bounty_scores)
    violations = validate_scores(thresholds, scores)

    if violations:
        print("\nInvariant violations:\n" + "\n".join(violations))
        sys.exit(1)
    
    print("All invariants satisfied!")
    sys.exit(0)

if __name__ == "__main__":
    main()