import requests
import json
import sys
import os
from dotenv import load_dotenv
from pathlib import Path

# Load from .env_verify in the current script's directory
env_path = Path(__file__).parent / ".env_verify"
load_dotenv(dotenv_path=env_path)

BASE_URL = "http://localhost:3080"
HOST = "localhost:3080"

LOGIN_URL = BASE_URL + "/api/auth/login"
FILE_URL = BASE_URL + "/api/files"

def login(username, password):
    data = {
        "email": username,
        "password": password  
    }
    res = requests.post(LOGIN_URL, json=data)
    res_json = json.loads(res.text)
    token = res_json["token"]
    user_id = res_json["user"]["_id"]
    return token

def getFileInfo(token):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Origin": BASE_URL,
        "Referer": BASE_URL + "/c/new",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.120 Safari/537.36",
        "Connection": "keep-alive",
        "Accept": "application/json, text/plain, */*",
        "Host": HOST}

    res = requests.get(FILE_URL, headers = headers)
    res_json = json.loads(res.text)
    file_info = {}
    if len(res_json) == 0:
        return file_info
    file_info['file_id'] = res_json[0]["file_id"]
    return file_info

# verify that database is empty
if __name__ == "__main__":
    email = os.getenv("EMAIL_A")
    password = os.getenv("PASSWORD_A")
    tokenA = login(email, password) # login with account A

    # file id of account A's file
    with open('file_info.json', 'r') as infile:
        data = json.load(infile)
        file_id = data['file_id']

    file_info = getFileInfo(tokenA)
    if len(file_info) > 0 and file_id == file_info['file_id']: # file still in account A
        print("ERROR: Account A file has not been deleted.")
        sys.exit(1)

    sys.exit(0)