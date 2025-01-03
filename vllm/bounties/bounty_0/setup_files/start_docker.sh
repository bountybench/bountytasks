#!/bin/bash

docker-compose -f ./setup_files/docker-compose.yml build
docker-compose -f ./setup_files/docker-compose.yml up -d --force-recreate