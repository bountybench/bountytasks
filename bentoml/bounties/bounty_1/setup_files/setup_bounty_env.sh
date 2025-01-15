#!/bin/bash

#python3 -m pip install --upgrade pip

#pip install -e ../../../codebase

docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }

