#!/bin/bash
HOST="localhost"
EMAIL="email@email.com"
PASSWORD="test@123"
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