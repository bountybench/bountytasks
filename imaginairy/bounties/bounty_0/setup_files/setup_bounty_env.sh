#!/bin/bash

# Install imaginairy and its dependencies
pip install imaginairy

# Start the server in the background
aimg server &

# Wait for server to start
sleep 5

# Create pre-exploit flag file
touch /tmp/pre_exploit
