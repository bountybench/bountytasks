import re
from bs4 import BeautifulSoup
import html
import os

def format_html(input_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    soup = BeautifulSoup(content, 'html.parser')

    formatted_content = []

    # Title
    title = soup.find('h1', id='title')
    if title:
        formatted_content.append(title.text.strip())
        formatted_content.append('')

    # Summary
    summary = soup.find('div', class_='spec-full-summary-content')
    if summary:
        formatted_content.append("Summary:")
        for p in summary.find_all('p'):
            formatted_content.append(p.text.strip())
        formatted_content.append('')

    # Timeline
    timeline = soup.find('div', class_='spec-report-timeline')
    if timeline:
        formatted_content.append("Timeline:")
        for item in timeline.find_all('div', class_='timeline-item'):
            username = item.find('a', class_='spec-profile-name-with-popover')
            action = item.find('span', class_='spec-activity-comment') or item.find('span', class_='spec-activity-bug-triaged') or item.find('span', class_='spec-activity-report-severity-updated') or item.find('span', class_='spec-activity-cve-id-added') or item.find('span', class_='spec-activity-bounty-awarded') or item.find('span', class_='spec-activity-bug-resolved') or item.find('span', class_='spec-activity-agreed-on-going-public') or item.find('span', class_='spec-activity-report-became-public')
            timestamp = item.find('span', class_='timeline-timestamp')
            
            if username and action and timestamp:
                formatted_content.append(f"{username.text.strip()} {action.text.strip()} {timestamp.text.strip()}")
            
            content = item.find('div', class_='interactive-markdown')
            if content:
                formatted_content.append(content.text.strip())
            formatted_content.append('')

    # Metadata
    metadata = soup.find('div', id='actions-and-stats')
    if metadata:
        formatted_content.append("Metadata:")
        for div in metadata.find_all('div', class_='w-full'):
            label = div.find('span', class_='font-medium')
            if label:
                value = div.find('span', class_='opacity-50') or div.find('a', class_='mt-1')
                if value:
                    formatted_content.append(f"{label.text.strip()}: {value.text.strip()}")

    return '\n'.join(formatted_content)

def process_all_exploit_reports():
    for root, dirs, files in os.walk('./undici'): #File moved, will need to change path
        for file in files:
            if file == 'exploit_report.txt':
                input_path = os.path.join(root, file)
                output_path = os.path.join(root, 'formatted_exploit_report.txt')
                print(f"Processing: {input_path}")
                formatted_content = format_html(input_path)
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(formatted_content)
                print(f"Formatted report saved to: {output_path}")

# Usage
if __name__ == "__main__":
    process_all_exploit_reports()