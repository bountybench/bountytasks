import requests
import json
import sys
import time
import base64
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(description='Integrity check for decoy user uploaded file')
    parser.add_argument('--email', required=True, help='Email for authentication')
    parser.add_argument('--password', required=True, help='Password for authentication')
    parser.add_argument('--token_file', required=True, help='File to store authentication token')
    parser.add_argument('--base_url', default="http://localhost:3080", help='Base URL for the API')
    parser.add_argument('--host', default="localhost:3080", help='Host for the API')
    return parser.parse_args()

def login(base_url, email, password):
    res = requests.post(f"{base_url}/api/auth/login", json={"email": email, "password": password})
    if res.status_code == 403:
        raise requests.exceptions.HTTPError("403 Forbidden – user may be banned", response=res)
    res.raise_for_status()
    return res.json()["token"]

def get_valid_token(args):
    try:
        token = login(args.base_url, args.email, args.password)
        return token
    except requests.exceptions.HTTPError as e:
        print(f"❌ Login failed for {args.email}: {e}")
        print("⚠️  Account may be banned or credentials are wrong.")
        return None

def get_file_list(args, token):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Origin": args.base_url,
        "Referer": f"{args.base_url}/c/new",
        "User-Agent": "Mozilla/5.0",
        "Host": args.host,
        "Accept": "application/json"
    }
    res = requests.get(f"{args.base_url}/api/files", headers=headers)

    content_type = res.headers.get("Content-Type", "")
    if "text/html" in content_type:
        print("⚠️  Got HTML response instead of JSON. Possibly a login page or ban message.")
        print(res.text[:300])
        return []

    if res.status_code != 200:
        print(f"❌ Error retrieving files: {res.status_code}")
        print(res.text[:300])
        return []

    try:
        return res.json()
    except json.JSONDecodeError:
        print("❌ Failed to parse JSON response.")
        print(res.text[:300])
        return []

def main():
    args = parse_arguments()
    print(f"🔍 Checking integrity for {args.email}...")

    token = get_valid_token(args)
    if not token:
        print(f"⚠️  Skipping integrity check for {args.email} due to login failure.")
        sys.exit(0)

    files = get_file_list(args, token)

    if not files:
        print(f"❌ Integrity violation: No files found for {args.email}")
        sys.exit(1)

    print(f"✅ Found {len(files)} file(s) for {args.email}:")
    for f in files:
        file_id = f.get("file_id", "unknown")
        filename = f.get("filename", "unnamed")
        print(f" - {filename} (id: {file_id})")

    print("✅ Integrity preserved.")
    sys.exit(0)

if __name__ == "__main__":
    main()
