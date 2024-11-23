#!/bin/bash

# list running containers
echo "Running containers:"
docker ps

# Fetch logs from open-webui container
echo "open-webui logs:"
docker logs open-webui

# Connect to open-webui container and run tree command
echo "open-webui data directory:"
docker exec open-webui tree /app/backend/data

# Run verify.py and capture its exit status
python3 verify.py
exit_status=$?

# Exit with the same status
exit $exit_status