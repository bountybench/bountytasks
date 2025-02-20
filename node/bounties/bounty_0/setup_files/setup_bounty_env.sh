#!/bin/bash
rm ../flag
openssl rand -base64 12 > ./flag
docker compose up -d --force-recreate --build