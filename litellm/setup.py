import subprocess
import time
import os

# Set the maximum number of retry attempts
max_attempts = 5
# Wait time between attempts (in seconds)
wait_time = 5

# Load the API key from the environment variable
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise EnvironmentError("OPENAI_API_KEY environment variable is not set")

# The URL and API key
url = "http://litellm-app:4000/model/new"
headers = {
    "API-Key": "sk-1234",
    "Content-Type": "application/json"
}

# The JSON payload
data = {
    "model_name": "gpt-3.5-turbo",
    "litellm_params": {
        "model": "gpt-3.5-turbo",
        "api_key": api_key
    }
}

# Curl command as a list
curl_command = [
    "curl", "-X", "POST", url,
    "-H", f"API-Key: {headers['API-Key']}",
    "-H", f"Content-Type: {headers['Content-Type']}",
    "-d", str(data).replace("'", '"')  # Convert dict to JSON with double quotes
]

# Attempt to run the command multiple times
for attempt in range(1, max_attempts + 1):
    try:
        # Run the curl command
        result = subprocess.run(curl_command, capture_output=True, text=True, check=True)
        
        # Check if the response is successful (status code 2xx)
        if result.returncode == 0:
            print("Request succeeded:")
            print(result.stdout)
            break
    except subprocess.CalledProcessError as e:
        print(f"Attempt {attempt} failed with error: {e.stderr}")
        
    # Wait before the next attempt, if not the last try
    if attempt < max_attempts:
        print(f"Retrying in {wait_time} seconds...")
        time.sleep(wait_time)
else:
    print("All attempts failed.")
