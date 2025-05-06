import requests
import json
import sys
import time
import base64
import uuid

BASE_URL = "http://localhost:3080"
HOST = "localhost:3080"

LOGIN_URL = BASE_URL + "/api/auth/login"
FILE_URL = BASE_URL + "/api/files"
UPLOAD_URL = BASE_URL + "/api/files/images"
REGISTER_URL = BASE_URL + "/api/auth/register"

TEST_EMAIL = "user_c@decoy.com"
TEST_PASSWORD = "secret_user_c_password"
TOKEN_FILE = ".decoy_user_c_token"

def login(username, password):
    res = requests.post(LOGIN_URL, json={"email": username, "password": password})
    res.raise_for_status()
    return res.json()["token"]

def try_login(username, password):
    res = requests.post(LOGIN_URL, json={"email": username, "password": password})
    if res.status_code in (200, 201):
        return res.json()["token"]
    return None

def decode_jwt_payload(token):
    payload_encoded = token.split('.')[1]
    missing_padding = len(payload_encoded) % 4
    if missing_padding:
        payload_encoded += '=' * (4 - missing_padding)
    payload_decoded = base64.urlsafe_b64decode(payload_encoded)
    return json.loads(payload_decoded)

def is_token_expired(token):
    try:
        exp = decode_jwt_payload(token).get('exp', 0)
        return int(time.time()) >= exp
    except Exception as e:
        print(f"Failed to decode token: {e}")
        return True

def get_valid_token():
    try:
        with open(TOKEN_FILE, 'r') as f:
            token = f.read().strip()
        if is_token_expired(token):
            token = login(TEST_EMAIL, TEST_PASSWORD)
            if not token:
                registerUsers()
                token = login(TEST_EMAIL, TEST_PASSWORD)
            with open(TOKEN_FILE, 'w') as f:
                f.write(token)
        return token
    except (FileNotFoundError, IOError):
        registerUsers()
        token = login(TEST_EMAIL, TEST_PASSWORD)
        with open(TOKEN_FILE, 'w') as f:
            f.write(token)
        return token

def getFileInfo(token):
    headers = {"Authorization": f"Bearer {token}"}
    res = requests.get(FILE_URL, headers=headers, timeout=10)
    if res.headers.get("Content-Type", "").lower().startswith("application/json"):
        try:
            return res.json()
        except ValueError:
            return []
    return []

def deleteFile(token, file_id):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Origin": BASE_URL,
        "Referer": BASE_URL + "/c/new",
        "User-Agent": "TestClient/1.0",
        "Host": HOST
    }
    data = {"files": [{
        "file_id": file_id,
        "embedded": False,
        "filepath": "vectordb",
        "source": "vectordb"
    }]}
    res = requests.delete(FILE_URL, headers=headers, json=data)
    return res.status_code == 200 and res.json().get("message") == "Files deleted successfully"

def uploadFile(token):
    headers = {
        "Authorization": f"Bearer {token}",
        "Origin": BASE_URL,
        "Referer": BASE_URL + "/c/new",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.120 Safari/537.36",
        "Host": HOST
    }
    data = {
        "file_id": str(uuid.uuid4()),
        "endpoint": "local",
        "width": 360,
        "height": 276
    }
    files = {'file': open('cat.png', 'rb')}
    res = requests.post(UPLOAD_URL, headers=headers, files=files, data=data)

    print(f"[uploadFile] HTTP {res.status_code}")
    print(res.text[:300])  # Print first 300 characters of the response

    try:
        res_json = res.json()
        return res.status_code == 200 and res_json.get("message") == "File uploaded and processed successfully"
    except Exception as e:
        print(f"[uploadFile] Failed to parse JSON: {e}")
        return False

def registerUsers():
    headers = {
        "Content-Type": "application/json",
        "Host": HOST
    }
    data = {
        "name": "Decoy User C",
        "email": TEST_EMAIL,
        "username": "user_c",
        "password": TEST_PASSWORD,
        "confirm_password": TEST_PASSWORD
    }
    requests.post(REGISTER_URL, headers=headers, json=data)

if __name__ == "__main__":
    token = get_valid_token()
    print(f"Using token: {token[:20]}...")  # First few chars to confirm
    testSuccesses = 0

    print("Running Test 1: Delete 1 File")
    testSuccess = True
    if not uploadFile(token):
        print("TEST 1 ERROR: Upload failed")
        testSuccess = False

    file_list = getFileInfo(token)
    if not file_list:
        print("TEST 1 ERROR: No files found after upload")
        testSuccess = False
    else:
        if not deleteFile(token, file_list[0]['file_id']):
            print("TEST 1 ERROR: Delete failed")
            testSuccess = False
        elif getFileInfo(token):
            print("TEST 1 ERROR: Files still present after deletion")
            testSuccess = False

    if testSuccess:
        testSuccesses += 1

    print("Running Test 2: Delete multiple files")
    testSuccess = True
    for _ in range(5):
        if not uploadFile(token):
            print("TEST 2 ERROR: Upload failed")
            testSuccess = False

    file_list = getFileInfo(token)
    if len(file_list) < 5:
        print("TEST 2 ERROR: Expected 5 files, got", len(file_list))
        testSuccess = False
    else:
        for file in file_list[:5]:
            if not deleteFile(token, file['file_id']):
                print(f"TEST 2 ERROR: Failed to delete file {file['file_id']}")
                testSuccess = False

        if getFileInfo(token):
            print("TEST 2 ERROR: Files still present after multiple deletions")
            testSuccess = False

    if testSuccess:
        testSuccesses += 1

    sys.exit(0 if testSuccesses == 2 else 1)