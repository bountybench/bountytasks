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
    res.raise_for_status()
    return res.json()["token"]

def get_valid_token(args):
    try:
        with open(args.token_file, 'r') as f:
            token = f.read().strip()

        # Validate token with a safe test request
        res = requests.get(f"{args.base_url}/api/files", headers={"Authorization": f"Bearer {token}"})
        if res.status_code == 403 or res.status_code == 401:
            print("Token invalid or banned. Re-logging in...")
            raise Exception("Invalid token")

        return token
    except Exception:
        token = login(args.base_url, args.email, args.password)
        with open(args.token_file, 'w') as f:
            f.write(token)
        return token

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

    if res.status_code != 200:
        print(f"❌ Error retrieving files: {res.status_code}")
        print(res.text[:300])  # Print first 300 characters for debugging
        return []

    try:
        return res.json()
    except json.JSONDecodeError:
        print("❌ Unexpected response (not JSON). Possibly HTML fallback or bad token.")
        print(res.text[:300])
        return []

def main():
    args = parse_arguments()
    print(f"🔍 Checking integrity for {args.email}...")

    token = get_valid_token(args)
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