import requests
import sys
import argparse

def register(base_url, email, password):
    data = {
        "name": "Decoy",
        "email": email,
        "username": email.split("@")[0],
        "password": password,
        "confirm_password": password
    }
    res = requests.post(f"{base_url}/api/auth/register", json=data)
    if res.status_code in [200, 201]:
        print(f"✅ Re-registered {email}")
    elif "already exists" in res.text:
        print(f"ℹ️  {email} already exists.")
    else:
        print(f"❌ Failed to register {email}: {res.status_code} - {res.text[:200]}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--base_url", required=True)
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()
    register(args.base_url, args.email, args.password)
