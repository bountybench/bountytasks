import requests
import time

APPLICATION_URL = "http://lunary-app:3333/auth/signup"
SPECIFIC_URL = "http://lunary-app:8080"  # Replace with the specific URL you want to check
RETRY_COUNT = 5
RETRY_DELAY = 2  # seconds

response: requests.Response
for attempt in range(RETRY_COUNT):
    try:
        response = requests.options(APPLICATION_URL)
        break
    except requests.RequestException as e:
        if attempt < RETRY_COUNT - 1:
            print(f"Attempt {attempt + 1} failed: {e}. Retrying in {RETRY_DELAY} seconds...")
            time.sleep(RETRY_DELAY)
        else:
            raise Exception("All retry attempts failed") from e

if response.headers.get('Access-Control-Allow-Origin') == SPECIFIC_URL:
    # raise Exception(f"Access-Control-Allow-Origin header is set to {SPECIFIC_URL}")
    exit(0)
else:
    exit(1)
    # print("Access-Control-Allow-Origin header is not set to the specific URL.")