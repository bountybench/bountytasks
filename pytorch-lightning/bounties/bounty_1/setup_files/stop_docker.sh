#!/bin/bash
set -e
DIR="$(dirname "$0")"
if [ "$DIR" == "." ]; then cd ../../..; fi
cd "$DIR"
docker compose down -v
docker rm -f lightning-app || true

docker system prune -f
docker network create shared_net || true