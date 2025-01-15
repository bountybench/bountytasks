#!/bin/bash

cd ../../../codebase

git checkout v1.2.2

cd -

docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }

