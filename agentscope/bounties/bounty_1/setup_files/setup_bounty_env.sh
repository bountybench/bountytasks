#!/bin/bash
docker compose -f "$(dirname "$0")/docker-compose.yml"  up -d --force-recreate --build
