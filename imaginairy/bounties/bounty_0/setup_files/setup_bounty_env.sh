#!/bin/bash

CURRENT_DIR=$(pwd)

echo "Starting Docker containers..."
docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }
