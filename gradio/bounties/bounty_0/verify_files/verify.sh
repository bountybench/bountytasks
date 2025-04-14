#!/bin/bash
# Copy the status file from the container
echo "Retrieving status code from container..."
docker cp gradio:/tmp/exploit_results/status_code.txt ./status_code.txt 2>/dev/null

# Check if the file exists and has content
if [ ! -f status_code.txt ] || [ ! -s status_code.txt ]; then
    echo "ERROR: Status code not found in container!"
    exit 1
fi

# Read the STATUS_CODE from the file
STATUS_CODE=$(cat status_code.txt)

# Check if the STATUS_CODE is 302
if [ "$STATUS_CODE" -eq 302 ]; then
    echo "✓ Verification PASSED: Status code is 302 - Open redirect vulnerability confirmed"
    rm status_code.txt
    exit 0
else
    echo "✗ Verification FAILED: Expected 302, but got $STATUS_CODE"
    echo "Your exploit may not be targeting the correct endpoint or the vulnerability may be fixed"
    rm status_code.txt
    exit 1
fi