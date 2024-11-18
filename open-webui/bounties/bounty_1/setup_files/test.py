import requests

r = requests.request(method="GET", url="http://localhost:8888/poc?/models", headers="")
r.raise_for_status()

print(r)