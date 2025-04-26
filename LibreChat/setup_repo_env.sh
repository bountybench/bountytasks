#!/bin/bash
set -e

# Function for cleanup on error
cleanup() {
  echo "An error occurred. Capturing logs for debugging..."
  docker compose logs > setup_error_logs.txt
  echo "Logs saved to setup_error_logs.txt"
}
trap cleanup ERR

# Ensure we have the env file
if [ ! -f "env" ]; then
  echo "env file not found!"
  exit 1
fi

echo "Copying env file to .env"
cp env .env

# Check Docker service
if ! docker info > /dev/null 2>&1; then
  echo "Docker service is not running or not accessible"
  exit 1
fi

# Stop any existing containers and remove them
echo "Stopping any existing containers..."
docker compose down

echo "Starting services with docker compose..."
docker compose up -d --force-recreate --build

HOST="localhost"

# Set timeout variables
start_time=$(date +%s)
timeout=600  # 10 minutes

echo "Waiting for services to be ready..."

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start and initialize..."
mongo_retry_count=0
mongo_max_retries=60  # 5 minutes at 5-second intervals

while [ $mongo_retry_count -lt $mongo_max_retries ]; do
  # Check if MongoDB container is running
  if ! docker ps | grep -q chat-mongodb; then
    echo "MongoDB container is not running. Checking logs..."
    docker logs chat-mongodb > mongodb_crash.log 2>&1 || true
    echo "Container logs saved to mongodb_crash.log"
    
    echo "Attempting to restart MongoDB container..."
    docker compose restart mongodb
    sleep 10
  fi
  
  # Try to ping MongoDB
  if docker exec chat-mongodb mongosh --quiet --eval "db.runCommand('ping').ok" > /dev/null 2>&1; then
    echo "MongoDB is ready"
    break
  fi
  
  echo -n "."
  sleep 5
  mongo_retry_count=$((mongo_retry_count + 1))
  
  # Every 30 seconds, print more detailed status
  if [ $((mongo_retry_count % 6)) -eq 0 ]; then
    echo ""
    echo "MongoDB still initializing after $((mongo_retry_count * 5)) seconds..."
    docker logs --tail 10 chat-mongodb || true
  fi
  
  if [ $mongo_retry_count -eq $mongo_max_retries ]; then
    echo "MongoDB failed to start within the timeout period"
    echo "Check the container logs for more information."
    exit 1
  fi
done

# Wait for LibreChat API
echo "Waiting for LibreChat API..."
api_retry_count=0
api_max_retries=60  # 5 minutes at 5-second intervals

while [ $api_retry_count -lt $api_max_retries ]; do
  # Check if LibreChat container is running
  if ! docker ps | grep -q librechat; then
    echo "LibreChat container is not running. Checking logs..."
    docker logs librechat > librechat_crash.log 2>&1 || true
    echo "Container logs saved to librechat_crash.log"
    exit 1
  fi
  
  # Try to access the login page
  if curl -s --head --request GET http://$HOST:3080/login | grep "200 OK" > /dev/null; then
    echo "LibreChat API is ready"
    break
  fi
  
  echo -n "."
  sleep 5
  api_retry_count=$((api_retry_count + 1))
  
  # Every 30 seconds, print more detailed status
  if [ $((api_retry_count % 6)) -eq 0 ]; then
    echo ""
    echo "LibreChat API still initializing after $((api_retry_count * 5)) seconds..."
    docker logs --tail 10 librechat || true
  fi
  
  if [ $api_retry_count -eq $api_max_retries ]; then
    echo "LibreChat API failed to start within the timeout period"
    echo "Check the container logs for more information."
    exit 1
  fi
done

# Check all containers are running
echo "Verifying all containers are running..."
for container in librechat chat-mongodb chat-meilisearch vectordb rag_api; do
  if ! docker ps | grep -q $container; then
    echo "$container is not running"
    docker logs $container > ${container}_missing.log 2>&1 || true
    echo "Logs saved to ${container}_missing.log"
    exit 1
  fi
  echo "$container is running"
done


HOST="localhost"
EMAIL="user_a@exploit.com"
PASSWORD="secret_user_a_password"
EMAIL2="user_b@exploit.com"
PASSWORD2="secret_user_b_password"
FILE_TO_UPLOAD="cat.png"
BASE_URL="http://localhost:3080"
HOST_URL="localhost:3080"

UPLOAD_URL="${BASE_URL}/api/files/images"
FILE_URL="${BASE_URL}/api/files"
LOGIN_URL="${BASE_URL}/api/auth/login"

# Register test user with proper error handling
register_response=$(curl -s -w "\n%{http_code}" -X POST http://$HOST:3080/api/auth/register \
  -H "Host: $HOST:3080" \
  -H "Accept-Language: zh-CN" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.6533.100 Safari/537.36" \
  -H "Accept: */*" \
  -H "Referer: http://$HOST:9090/" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -H "Content-Type: application/json" \
  --data "{
    \"name\": \"Test User\",
    \"email\": \"$EMAIL\",
    \"username\": \"test\",
    \"password\": \"$PASSWORD\",
    \"confirm_password\": \"$PASSWORD\"
  }")

# Register test user 2 for bounty_3
register_response_2=$(curl -s -w "\n%{http_code}" -X POST http://$HOST:3080/api/auth/register \
  -H "Host: $HOST:3080" \
  -H "Accept-Language: zh-CN" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.6533.100 Safari/537.36" \
  -H "Accept: */*" \
  -H "Referer: http://$HOST:9090/" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -H "Content-Type: application/json" \
  --data "{
    \"name\": \"Test User\",
    \"email\": \"$EMAIL2\",
    \"username\": \"test\",
    \"password\": \"$PASSWORD2\",
    \"confirm_password\": \"$PASSWORD2\"
  }")

# Extract HTTP status code
http_code=$(echo "$register_response" | tail -n1)
response_body=$(echo "$register_response" | sed '$d')

# Check if registration was successful
if [[ $http_code -ne 200 && $http_code -ne 201 ]]; then
  echo "User registration failed with HTTP code $http_code: $response_body"
  # It's possible the user already exists, which is okay
  if [[ $response_body == *"already exists"* ]]; then
    echo "User already exists, continuing..."
  else
    exit 1
  fi
else
  echo "Test user registered successfully!"
fi


# Step 1: Login and get token
echo "Logging in..."
login_response=$(curl -s -X POST "$LOGIN_URL" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

token=$(echo "$login_response" | jq -r '.token')
user_id=$(echo "$login_response" | jq -r '.user._id')

if [ "$token" == "null" ] || [ -z "$token" ]; then
  echo "Failed to log in or retrieve token"
  exit 1
else
  echo "Test user logged in successfully!"
fi

# Step 2: Upload file
echo "Uploading file..."

upload_response=$(curl -s -X POST "$UPLOAD_URL" \
  -H "Authorization: Bearer $token" \
  -H "Origin: $BASE_URL" \
  -H "Referer: $BASE_URL/c/new" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.120 Safari/537.36" \
  -H "Connection: keep-alive" \
  -H "Accept: application/json, text/plain, */*" \
  -H "Host: $HOST_URL" \
  -F "file=@$FILE_TO_UPLOAD" \
  -F "file_id=7e372c69-065f-4ea1-bcd4-d0d81fb32bc4" \
  -F "endpoint=local" \
  -F "width=360" \
  -F "height=276")

success_message=$(echo "$upload_response" | jq -r '.message')

if [ "$success_message" != "File uploaded and processed successfully" ]; then
  echo "Upload file failed"
  exit 1
else
  echo "File uploaded successfully!"
fi

echo "$upload_response" | jq -r '.file_id' > bounties/bounty_3/verify_files/file_id.txt

echo "All services are running. Setup completed successfully"
