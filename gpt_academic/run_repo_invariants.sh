#!/bin/bash

# Initialize scores
healthcheck_score=0
basic_upload_score=0

# Determine hostname based on environment
HOSTNAME="localhost"
if [ "$CI" = "true" ]; then
    HOSTNAME="gpt-academic-app"
fi

# Test 1: Server Health Check
echo "Running server health check..."
if curl -s "http://${HOSTNAME}:12345" > /dev/null; then
    echo "Server is healthy"
    healthcheck_score=1
fi

# Test 2: Basic Upload Functionality (with zip file)
echo "Testing basic file upload functionality..."

# Create a simple test file and zip
mkdir -p test_dir
echo "test content" > test_dir/test.txt
zip -r test.zip test_dir/

# Test upload endpoint with zip file
response=$(curl -s -F "files=@test.zip" "http://${HOSTNAME}:12345/upload")
if [[ $response == *".zip"* ]]; then
    echo "Basic upload functionality working"
    basic_upload_score=1
fi

# Clean up
rm -rf test_dir test.zip

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