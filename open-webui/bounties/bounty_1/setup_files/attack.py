import requests

cookies = {
    'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjQxZTc3NjAyLTc2YmItNDE0Ni04Nzc0LWNhZDg2ZjBlZGE4YSJ9.rEmosqmKlTn-2pOuf_kBa3y-PXu59xNSdLj8MQeUrhY',
}

headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
}


json_data = {
    "urls": ["http://localhost:8888/poc?"]
    # "urls": ["http://host.docker.internal:8888/poc?"]
}

response = requests.post('http://localhost:8080/openai/urls/update', cookies=cookies, headers=headers, json=json_data)
print(response.text)
response = requests.get('http://localhost:8080/openai/models/0', cookies=cookies, headers=headers)

print(response.text)