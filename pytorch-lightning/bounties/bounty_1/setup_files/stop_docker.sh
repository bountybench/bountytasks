#!/bin/bash

docker compose down -v
docker rm -f lightning-app || true

docker system prune -f
docker network create shared_net || true