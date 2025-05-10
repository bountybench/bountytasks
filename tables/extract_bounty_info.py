import argparse
import csv
import json
import os
import re
from datetime import datetime
from typing import Any, Dict, List

from bs4 import BeautifulSoup


def bounty_iterate_parser(
    bounties: Dict, metadata_fields: List, root_dir: str, output_file: str
) -> Dict:
    """
    Iterate through all of the bounties and scrape data from their writeup.html and metadata files.
    Then write this information to a CSV.
    """
    rows = {}
    for repo in os.listdir(root_dir):
        repo_path = os.path.join(root_dir, repo, "bounties")
        if repo in bounties.keys():
            if os.path.isdir(repo_path):
                for bounty_folder in os.listdir(repo_path):
                    bounty_num = -1
                    try:
                        bounty_num = int(bounty_folder.split("_")[1])
                    except (IndexError, ValueError):
                        continue

                    if bounty_num in bounties[repo]:
                        bounty_path = os.path.join(repo_path, bounty_folder)
                        if repo not in rows.keys():
                            rows[repo] = {}

                        if bounty_num not in rows[repo].keys():
                            rows[repo][bounty_num] = {}

                        try:
                            metadata_values = bounty_metadata_parser(
                                bounty_path, metadata_fields
                            )
                            metadata_values.update(
                                bounty_writeup_parser(bounty_path, metadata_fields)
                            )
                            rows[repo][bounty_num].update(metadata_values)
                        except OSError as e:
                            print(
                                "Error in" + repo + " " + bounty_folder + ": " + str(e)
                            )

    csv_header = ["Repository", "Bounty Number"]
    csv_header.extend(metadata_fields)
    save_bounties_to_sorted_csv(bounties, rows, csv_header, output_file)

    return rows


def save_bounties_to_sorted_csv(
    bounties: Dict, rows: Dict, csv_header: List, output_file: str
):
    """
    Write the bounty information in rows to a CSV with specified headers and location
    """

    csv_rows = []
    for bounty, numbers in bounties.items():
        if bounty in rows.keys():
            for number in numbers:
                if number in rows[bounty].keys():
                    csv_rows.append([bounty, number])
                    csv_rows[-1].extend(f for f in rows[bounty][number].values())

    csv_rows.sort(key=lambda x: (x[0].lower(), int(x[1])))

    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(csv_header)
        writer.writerows(csv_rows)


def bounty_writeup_parser(bounty_path: str, metadata_fields: List) -> Dict:
    """
    Parses the writeup.html file for the date and adds this in the correct formatting to the CSV.
    Currently only adds date information, but other features from the html can also be added
    """
    writeup_path = os.path.join(bounty_path, "writeup/writeup.html")
    metadata_values = {}
    if os.path.isfile(writeup_path):
        if "Date" in metadata_fields:
            try:
                with open(writeup_path, "r", encoding="utf-8") as f:
                    soup = BeautifulSoup(f, "html.parser")
                    text = soup.get_text()

                    date_match = re.search(
                        r"Reported on (\w+ \d{1,2})(?:st|nd|rd|th)? (\d{4})", text
                    )

                    if date_match:
                        month_day = date_match.group(1)  # e.g., 'Apr 7'
                        year = date_match.group(2)  # e.g., '2024'
                        date_str = f"{month_day} {year}"  # 'Apr 7 2024'

                        try:
                            date_obj = datetime.strptime(date_str, "%b %d %Y")
                            report_date = date_obj.strftime("%m/%d/%y")
                            metadata_values["Date"] = report_date
                        except ValueError:
                            pass

            except Exception as e:
                print(f"Error parsing writeup HTML from {writeup_path}: {e}")
    else:
        raise OSError("No writeup HTML file from bounty")
    return metadata_values


def bounty_metadata_parser(bounty_path: str, metadata_fields: List) -> Dict:
    """
    Collects information from the bounty metadata based on the fields specified
    """
    metadata_path = os.path.join(bounty_path, "bounty_metadata.json")
    metadata_values = {}
    try:
        with open(metadata_path, "r") as f:
            metadata = json.load(f)
        metadata_values = {
            field: metadata[field]
            for field in metadata_fields
            if field in metadata.keys()
        }
    except (OSError, json.JSONDecodeError):
        raise OSError("Could not find bounty metadata for bounty")

    return metadata_values


def save_bounty_metadata(
    root_dir: str, output_csv: str, bounty_list: str = "bounty_list.json"
) -> Dict:
    """
    Uses the set of 32 bounties as determined by the spreadsheet,
    and the headers of the data table we want to include to generate the table
    """
    with open(bounty_list, "r") as f:
        bounties_used = json.load(f)

    metadata_fields = [
        "bounty_link",
        "CWE",
        "CVE",
        "disclosure_bounty",
        "patch_bounty",
        "severity",
    ]

    writeup_fields = ["Date"]

    metadata_fields.extend(writeup_fields)

    return bounty_iterate_parser(bounties_used, metadata_fields, root_dir, output_csv)


if __name__ == "__main__":
    """
    This allows you to specify the input/output file paths to generate the CSV

    You can generate the CSV in this folder by navigating to the table director and running python extract_bounty_info.py.
    """
    parser = argparse.ArgumentParser(description="Scrape CSV metadata")
    parser.add_argument(
        "--root_dir", default="..", help="relative location to bounties"
    )
    parser.add_argument(
        "--output_file_path",
        default="bounty_data.csv",
        help="where the csv will be created",
    )
    args = parser.parse_args()

    # Can use the JSON format of the rows if wanted as well
    rows = save_bounty_metadata(args.root_dir, args.output_file_path)
