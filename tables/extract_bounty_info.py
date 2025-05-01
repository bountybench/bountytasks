import os
import json
import csv
import re
from bs4 import BeautifulSoup
from datetime import datetime

root_dir = '..'

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
metadata_fields = ["bounty_link", "CWE", "CVE", "disclosure_bounty", "patch_bounty"]

# CSV Header
csv_header = ["Repository", "Bounty Number"]
csv_header.extend(metadata_fields)
csv_header.append("Date")

# Collect data
rows = []

for repo in os.listdir(root_dir):
    repo_path = os.path.join(root_dir, repo, "bounties")
    if repo in bounties_used.keys():
        if os.path.isdir(repo_path):
            for bounty_folder in os.listdir(repo_path):
                try:
                    bounty_num = int(bounty_folder.split('_')[1])
                except (IndexError, ValueError):
                    continue  # Skip folders that don't match the expected pattern

                if bounty_num in bounties_used[repo]:

                    bounty_path = os.path.join(repo_path, bounty_folder)

                    metadata_values = [""] * len(metadata_fields)
                    report_date = ""  # Default if not found

                    # Get metadata from JSON
                    metadata_path = os.path.join(bounty_path, "bounty_metadata.json")
                    if os.path.isfile(metadata_path):
                        try:
                            with open(metadata_path, 'r') as f:
                                metadata = json.load(f)
                                metadata_values = [metadata.get(field, "") for field in metadata_fields]
                        except Exception as e:
                            print(f"Error reading metadata from {metadata_path}: {e}")

                    # Get date from writeup HTML
                    writeup_path = os.path.join(bounty_path, "writeup/writeup.html")
                    if os.path.isfile(writeup_path):
                        try:
                            with open(writeup_path, 'r', encoding='utf-8') as f:
                                soup = BeautifulSoup(f, 'html.parser')
                                text = soup.get_text()
                                
                                date_match = re.search(r'Reported on (\w+ \d{1,2})(?:st|nd|rd|th)? (\d{4})', text)
                                print(date_match)
                                
                                if date_match:
                                    month_day = date_match.group(1)  # e.g., 'Apr 7'
                                    year = date_match.group(2)       # e.g., '2024'
                                    date_str = f"{month_day} {year}" # 'Apr 7 2024'

                                    try:
                                        date_obj = datetime.strptime(date_str, '%b %d %Y')
                                        report_date = date_obj.strftime('%m/%d/%y')
                                    except ValueError:
                                        pass
                        except Exception as e:
                            print(f"Error parsing writeup HTML from {writeup_path}: {e}")

                    # Build final row
                    row = [repo, str(bounty_num)] + metadata_values + [report_date]
                    rows.append(row)

# Sort and write to CSV
rows.sort(key=lambda x: (x[0].lower(), int(x[1])))

with open(output_csv, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(csv_header)
    writer.writerows(rows)
