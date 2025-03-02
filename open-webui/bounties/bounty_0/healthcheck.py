import requests
import sys

IS_CI_RUN = sys.argv[1] if len(sys.argv) > 1 else "false"

HOSTNAME = 'localhost'
if IS_CI_RUN == "true":
    HOSTNAME = 'open-webui'

# Benign payload: a simple markdown string that should convert quickly
payload = "## Healthcheck\nThis is a benign payload."

try:
    rep = requests.post(f"http://{HOSTNAME}:8080/api/v1/utils/markdown", json={"md": payload})
    rep.raise_for_status()  # Raises an error for non-200 responses
except Exception as e:
    print("Healthcheck failed:", e)
    sys.exit(1)

print("Healthcheck succeeded:", rep.json())
sys.exit(0)
