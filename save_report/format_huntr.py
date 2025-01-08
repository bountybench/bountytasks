import re
from bs4 import BeautifulSoup
import html
import os

def format_html(input_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    soup = BeautifulSoup(content, 'html.parser')

    formatted_content = []

    # Title and status
    title = soup.find('h1', id='title')
    if title:
        formatted_content.append(title.text.strip())
        status_span = soup.find('span', class_='mr-1 text-xs font-medium')
        if status_span:
            formatted_content.append(status_span.text.strip())
        report_date = soup.find('p', class_='ml-3 mt-1 self-center text-xs font-medium')
        if report_date:
            formatted_content.append(report_date.text.strip())
        formatted_content.append('')

    # Description and Proof of Concept
    markdown_body = soup.find('div', class_='markdown-body')
    if markdown_body:
        for child in markdown_body.children:
            if child.name == 'h1':
                formatted_content.append(f"\n{child.text}")
            elif child.name in ['p', 'pre']:
                formatted_content.append(html.unescape(child.text.strip()))
            elif child.name == 'ul':
                for li in child.find_all('li'):
                    formatted_content.append(f"- {li.text.strip()}")

    # Comments and updates
    comments = soup.find_all('div', class_='relative w-full rounded-xl border border-white border-opacity-10 bg-10-percent px-4 py-2.5')
    for comment in comments:
        username = comment.find('a', class_='conversationStyle_username__NihmK')
        if username:
            formatted_content.append(f"\n{username.text}")
        role = comment.find('span', class_='bg-red-600') or comment.find('span', class_='bg-blue-500') or comment.find('span', class_='bg-yellow-400')
        if role:
            formatted_content.append(role.text)
        comment_text = comment.find('div', class_='markdown-body -mb-4 !font-montserrat !text-sm')
        if comment_text:
            formatted_content.append(comment_text.text.strip())

    # Metadata
    meta_container = soup.find('div', id='meta-container')
    if meta_container:
        formatted_content.append("\nMetadata:")
        for div in meta_container.find_all('div', class_='w-full'):
            div_text = ' '.join(div.stripped_strings)
            formatted_content.append(div_text)

    return '\n'.join(formatted_content)

def process_all_exploit_reports():
    for root, dirs, files in os.walk('.'):#File moved, will need to change path
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