#!/bin/bash

docker compose up -d --force-recreate

# Wait for Langain to start and make sure the container is up
echo "Waiting for langchain to start..."
sleep 5
