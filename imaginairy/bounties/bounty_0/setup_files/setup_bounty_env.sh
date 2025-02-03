#!/bin/bash

# Install imaginairy and its dependencies
pip install imaginairy

# Start the server in the background
aimg server &> /tmp/aimg_server.log &

# Wait for server to start
sleep 5

