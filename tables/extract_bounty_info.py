import os
import json
import csv

root_dir = '.'

bounties_used = {
    'InvokeAI': [0],
    'LibreChat': [0, 1, 3],
    'agentscope': [0],
    'astropy': [0],
    'bentoml': [0, 1],
    'composio': [0],
    'fastapi': [0],
    'gluon-cv': [0],
    'gpt_academic': [0],
    'gradio': [0, 1, 2],
    'gunicorn': [0],
    'kedro': [0],
    'lunary': [0, 1, 2],
    'mlflow': [0, 1, 2, 3],
    'parse-url': [0],
    'scikit-learn': [0],
    'setuptools': [0],
    'undici': [0],
    'vllm': [0],
    'yaml': [0],
    'zipp': [0]
}
output_csv = 'bounty_data.csv'

# Desired fields from metadata
fields = ["bounty_link", "CWE", "CVE", "disclosure_bounty", "patch_bounty"]
# Prepare CSV header
csv_header = ["Repository", "Bounty Number"] + fields

# Collect data
rows = []

for repo in os.listdir(root_dir):
    repo_path = os.path.join(root_dir, repo, "bounties")
    if repo in bounties_used.keys():
        if os.path.isdir(repo_path):
            for bounty_folder in os.listdir(repo_path):
                if (int)(bounty_folder.split('_')[1]) in bounties_used[repo]:
                    bounty_path = os.path.join(repo_path, bounty_folder)
                    metadata_path = os.path.join(bounty_path, "bounty_metadata.json")
                    if os.path.isfile(metadata_path):
                        try:
                            with open(metadata_path, 'r') as f:
                                metadata = json.load(f)
                                row = [repo, bounty_folder.split('_')[-1]]  # e.g., "bounty_0" -> "0"
                                for field in fields:
                                    row.append(metadata.get(field, ""))
                                rows.append(row)
                        except Exception as e:
                            print(f"Error reading {metadata_path}: {e}")

# Write to CSV
with open(output_csv, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(csv_header)
    writer.writerows(rows)
