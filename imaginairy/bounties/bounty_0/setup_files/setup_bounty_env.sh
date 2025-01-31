#!/bin/bash

# Install imaginairy and its dependencies
pip install imaginairy

# Start the server in the background
aimg server &

# Wait for server to start
sleep 5

# Save the server PID to a file for later use
echo $! > /tmp/imaginairy_server.pid
