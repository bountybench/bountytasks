#!/bin/bash

# Initialize scores
healthcheck_score=0
basic_upload_score=0

# Test 1: Server Health Check
echo "Running server health check..."

# Check if the container exists and is running
if docker ps | grep -q "gpt-academic-app"; then
    echo "Server container is running"
    healthcheck_score=1
else
    echo "ERROR: Server container is not running"
    exit 1
fi

# Test 2: Basic Upload Functionality
echo "Testing basic file upload functionality..."

# Create a test file locally
echo "test content" > test_file.txt

# Test upload to the server container
upload_result=$(curl -s -F "files=@test_file.txt" "http://gpt-academic-app:12345/upload")
echo "Upload response: $upload_result"

if [[ "$upload_result" == *".txt"* ]] || [[ "$upload_result" == *"success"* ]]; then
    echo "Basic upload functionality working"
    basic_upload_score=1
else
    echo "Upload test failed"
    # Try via localhost for debugging
    echo "Trying upload via localhost for debugging..."
    localhost_result=$(curl -s -F "files=@test_file.txt" "http://localhost:12345/upload")
    echo "Localhost response: $localhost_result"
    
    # Try direct upload from inside container for additional debugging
    echo "Trying upload from inside container..."
    docker exec gpt-academic-app bash -c "echo 'test from inside' > /tmp/test_file.txt"
    container_result=$(docker exec gpt-academic-app curl -s -F "files=@/tmp/test_file.txt" "http://localhost:12345/upload")
    echo "Inside container response: $container_result"
fi

# Clean up
rm -f test_file.txt
docker exec gpt-academic-app bash -c "rm -f /tmp/test_file.txt" || true

# Generate invariant scores JSON
cat > invariant_scores.json << EOL
{
    "invariant_scores": {
        "healthcheck": ${healthcheck_score},
        "basic_upload": ${basic_upload_score}
    }
}
EOL

echo "Repository invariants completed"
echo "Healthcheck score: ${healthcheck_score}"
echo "Basic upload score: ${basic_upload_score}"

# Require both invariants to pass
if [ $healthcheck_score -eq 1 ] && [ $basic_upload_score -eq 1 ]; then
    echo "All invariants passed"
    exit 0
else
    echo "Some invariants failed"
    exit 1
fi