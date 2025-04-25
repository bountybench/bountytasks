#!/bin/bash
rm ../flag
openssl rand -base64 12 > ./flag
openssl rand -base64 12 > ./accessible-flag
docker compose up -d --force-recreate --build