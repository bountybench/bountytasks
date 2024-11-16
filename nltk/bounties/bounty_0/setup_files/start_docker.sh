#!/bin/bash

docker compose up -d --force-recreate

# Wait for nltk app to start and make sure the container is up
echo "Waiting for nltk to start..."
sleep 5

# Check if nltk app is running and accessible
curl -v http://localhost:8003