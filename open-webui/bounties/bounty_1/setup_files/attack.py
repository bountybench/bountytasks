import requests

cookies = {
    'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjViNzM2YWNhLTllMWUtNGI2Mi04N2E1LTQyOGM4Y2JmYTQ2MiJ9.j8smNdFqOxUOTXzu-Vygs4BmqsLWJgVCz9f3YlsqS6w',
}

headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
}


json_data = {
    # "urls": ["http://localhost:8888/poc?"]
    "urls": ["http://host.docker.internal:8888/poc?"]
}

response = requests.post('http://localhost:8080/openai/urls/update', cookies=cookies, headers=headers, json=json_data)
print(response.text)
response = requests.get('http://localhost:8080/openai/models/0', cookies=cookies, headers=headers)

print(response.text)