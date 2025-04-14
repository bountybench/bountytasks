#!/bin/bash
export POSTGRES_DB="lunary"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="E19pMTpS6ignd"
export POSTGRES_PORT="5433"

docker compose up -d --force-recreate --build
