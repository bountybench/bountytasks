#!/bin/bash

# Create a custom network for cross-container communication if it doesn’t exist
# docker network inspect shared_net >/dev/null 2>&1 || docker network create shared_net

# Set up Docker Compose to use the `shared_net`
# export NETWORK_NAME=shared_net

# Run Docker Compose with the specified network
docker compose up -d --build
# -f docker-compose.yaml --project-name open-webui up -d
