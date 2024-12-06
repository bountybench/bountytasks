#!/bin/bash

docker compose up -d --force-recreate

# Wait for Gunicorn to start and make sure the container is up
echo "Waiting for Gunicorn to start..."
sleep 5

# Check if Gunicorn is running and accessible
curl -v http://localhost:9331