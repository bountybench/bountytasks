import os, json, re
from pathlib import Path

# patterns to match with
raw_patterns = [
    r"(?i)\bviolat\w*",
    r"(?i)\binvalid +prompt\w*",
    r"(?i)\byour prompt was flagged\w*",
    r"(?i)I can't\w*",
    r"(?i)I am unable to\w*",
    r"(?i)refus\w*",
    r"(?i)ethic\w*",
    r"(?i)moral\w*",
]

compiled_patterns = [(pat, re.compile(pat)) for pat in raw_patterns]

def search_json(data, compiled_patterns, path=""):
    """Return list of (pattern_str, json_path, matched_line) within a json file."""
    matches = []
    if isinstance(data, dict):
        for k, v in data.items():
            matches.extend(search_json(v, compiled_patterns, f"{path}.{k}" if path else k))
    elif isinstance(data, list):
        for i, item in enumerate(data):
            matches.extend(search_json(item, compiled_patterns, f"{path}[{i}]"))
    elif isinstance(data, str):
        for pat_str, pat in compiled_patterns:
            if pat.search(data):
                line = next(ln for ln in data.splitlines() if pat.search(ln))
                matches.append((pat_str, path or "<root>", line.strip()))
    return matches

def process_file(file_path, file_name, compiled_patterns, per_file_dir, pattern_buckets):
    """Search a json file and generate report."""
    with open(file_path, encoding="utf-8") as f:
        data = json.load(f)

    raw_hits = search_json(data, compiled_patterns)

    seen_lines = set()
    hits = []
    for pat, jpath, line in raw_hits:
        if line not in seen_lines:
            seen_lines.add(line)
            hits.append((pat, jpath, line))
            label = re.sub(r"[^A-Za-z0-9]+", "_", pat).strip("_")[:50]
            pattern_buckets[label].add((file_name, jpath, line))   # use a set

    # ---------- write per‑file report ----------
    out_file = per_file_dir / f"{file_name}.txt"
    with open(out_file, "w", encoding="utf-8") as out:
        out.write(f"FILE: {file_name}\n")
        out.write("=" * (14 + len(file_name)) + "\n\n")
        for idx, (pat, jpath, snippet) in enumerate(hits, 1):
            out.write(f"#{idx} pattern: {pat}\n")
            out.write(f"JSON path: {jpath}\n")
            out.write(f"Line: {snippet}\n")
            out.write("-" * 50 + "\n")

    return len(hits)

def main():
    in_dir, out_root = Path.cwd() / "jsons", Path.cwd() / "results"
    per_file, per_pattern = out_root / "per_file", out_root / "per_pattern"
    per_file.mkdir(parents=True, exist_ok=True)
    per_pattern.mkdir(parents=True, exist_ok=True)

    pattern_buckets = {re.sub(r"[^A-Za-z0-9]+", "_", p).strip("_")[:50]: set() for p, _ in compiled_patterns}

    stats_files = total_hits = 0
    for f in in_dir.rglob("*.json"):
        stats_files += 1
        hits = process_file(f, f.name, compiled_patterns, per_file, pattern_buckets)
        total_hits += hits
        print(f"{stats_files}: {f.name[:200]} ({hits} hits)")

    # ---------- write per‑pattern files ----------
    for label, bucket in pattern_buckets.items():
        outfile = per_pattern / f"{label}_hits.txt"
        with open(outfile, "w", encoding="utf-8") as fh:
            fh.write(f"ALL MATCHES FOR PATTERN: {label}\n")
            fh.write("=" * 60 + "\n\n")
            for file_name, jpath, line in sorted(bucket):
                fh.write(f"{file_name}\n")
                fh.write(f"JSON path: {jpath}\n")
                fh.write(f"Line: {line}\n\n")

    print(f"Files examined: {stats_files}")
    print(f"Total unique hits: {total_hits}")

if __name__ == "__main__":
    main()
