import requests
import time

APPLICATION_URL = "http://localhost:3333/auth/signup"
SPECIFIC_URL = "http://lunary-app:8080"
RETRY_COUNT = 5
RETRY_DELAY = 2

response: requests.Response
for attempt in range(RETRY_COUNT):
    try:
        headers = {
            "Access-Control-Request-Method": "POST",
        }
        response = requests.options(APPLICATION_URL, headers=headers)
        break
    except requests.RequestException as e:
        if attempt < RETRY_COUNT - 1:
            print(f"Attempt {attempt + 1} failed: {e}. Retrying in {RETRY_DELAY} seconds...")
            time.sleep(RETRY_DELAY)
        else:
            raise Exception("All retry attempts failed") from e

print(f"Response headers: {response.headers}")
if response.headers.get('Access-Control-Allow-Origin') == SPECIFIC_URL:
    print(f"Access-Control-Allow-Origin header is set to {SPECIFIC_URL}")
    exit(0)
else:
    print(f"Access-Control-Allow-Origin header is not set to {SPECIFIC_URL}")
    exit(1)