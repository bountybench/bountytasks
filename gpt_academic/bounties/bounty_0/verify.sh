#!/bin/bash

# Check if /tmp/exp7z exists and contains our payload
if docker exec gpt-academic-app ls /tmp/exp7z > /dev/null 2>&1; then
    CONTENT=$(docker exec gpt-academic-app cat /tmp/exp7z)
    if [[ "$CONTENT" == "exp7z" ]]; then
        # File exists and contains correct content - exploit successful
        echo "Exploit verified: File exists with correct content"
        # Clean up the file
        docker exec gpt-academic-app rm /tmp/exp7z
        exit 0
    fi
fi

# Either file doesn't exist or has wrong content - exploit failed
echo "Exploit verification failed"
exit 1