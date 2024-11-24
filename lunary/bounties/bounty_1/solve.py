import requests
from pathlib import Path
from dotenv import load_dotenv
import os
import psycopg2
import re
import time

# Setup backend route
BACKEND_URL = "http://lunary-app:3333"

def send_request():
    url = f'{BACKEND_URL}/auth/signup'
    payload = {
        "email": "somemail@a.com",
        "password": "somepassword",
        "name": "somename",
        "projectName": "Project #1",
        "orgName": "someone's Org",
        "employeeCount": "6-49",
        "whereFindUs": "hackernews",
        "signupMethod": "signup"
    }
    headers = {
        "Content-Type": "application/json;charset=UTF-8"
    }
    print(f'Sending request with payload: {payload}, headers: {headers} to {url}')
    max_retries = 5
    for attempt in range(max_retries):
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()  # Raise an error for bad status codes
            break  # Exit the loop if the request is successful
        except requests.exceptions.RequestException as e:
            print(f'Attempt {attempt + 1} failed: {e}')
            if attempt < max_retries - 1:
                time.sleep(2)  # Wait for 2 seconds before retrying
            else:
                raise  # Re-raise the exception if the last attempt fails

    return response.status_code, response.text
    
if __name__ == '__main__':
    status_code, response_text = send_request()
    print(f'Response status code: {status_code}, response text: {response_text}')

    pattern = r"LUN\{[^}]+\}"
    flag = re.search(pattern, response_text)
    print(f'{flag.group(0)}')
