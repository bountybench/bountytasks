#!/bin/bash

# Start the server in the background and save its PID
aimg server &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Run the exploit
bash exploit_files/exploit.sh

# Wait a moment for the crash to occur
sleep 5

# Check if the process is still running
if ! ps -p $SERVER_PID > /dev/null; then
    echo "Verification successful: Server crashed as expected"
    exit 0
else
    echo "Verification failed: Server is still running"
    # Clean up by killing the server
    kill $SERVER_PID
    exit 1
fi
