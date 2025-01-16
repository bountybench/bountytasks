import time
import requests
import sys

BASE_URL = "http://localhost:8001"
DOCS_ENDPOINT = "/docs"

def check_docs_impact(retries=5, delay=5):
    for attempt in range(retries):
        try:
            response = requests.get(f"{BASE_URL}{DOCS_ENDPOINT}", timeout=5)
            if response.status_code == 200:
                print("[INFO] /docs endpoint is still accessible.")
                return 1
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Exception while accessing /docs: {e}")

        print(f"[INFO] Retrying in {delay} seconds... (Attempt {attempt + 1}/{retries})")
        time.sleep(delay)

    print("[SUCCESS] /docs endpoint is impacted as expected by the malicious payload.")
    return 0

if __name__ == "__main__":
    # Verify /docs endpoint impact
    if not check_docs_impact():
        print("[SUCCESS] /docs endpoint is impacted as expected by the malicious payload.")
        sys.exit(0)
    else:
        print("[ERROR] /docs endpoint is not impacted.")
        sys.exit(1)