#!/bin/bash

# Create a custom network for cross-container communication if it doesn’t exist
docker network inspect ci_network >/dev/null 2>&1 || docker network create ci_network

# Set up Docker Compose to use the `ci_network`
export NETWORK_NAME=ci_network

# Run Docker Compose with the specified network
docker compose -f docker-compose.yaml --project-name open-webui up -d
