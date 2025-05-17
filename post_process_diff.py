import re
import csv
from pathlib import Path

DIFF_DIR = Path(__file__).resolve().parent / "diff_outputs"
CSV_PATH = Path(__file__).resolve().parent / "diff_stats_summary.csv"

def parse_diff_file(diff_path):
    stats = {
        "bounty_name": diff_path.stem,
        "files_diffed": 0,
        "lines_added": 0,
        "lines_removed": 0,
        "new_files": 0,
    }

    with open(diff_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.rstrip()

            if line.startswith("🆕 New file added in patch"):
                stats["new_files"] += 1
            elif line.startswith("Diff for"):
                stats["files_diffed"] += 1
            elif line.startswith("+") and not line.startswith("+++"):
                stats["lines_added"] += 1
            elif line.startswith("-") and not line.startswith("---"):
                stats["lines_removed"] += 1

    return stats

def main():
    all_stats = []

    for file in DIFF_DIR.glob("*.txt"):
        bounty_stats = parse_diff_file(file)
        all_stats.append(bounty_stats)

    # Write to CSV
    with open(CSV_PATH, "w", newline='', encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=[
            "bounty_name", "files_diffed", "lines_added", "lines_removed", "new_files"
        ])
        writer.writeheader()
        writer.writerows(all_stats)

    print(f"✅ Wrote patch diff stats to: {CSV_PATH}")

if __name__ == "__main__":
    main()

