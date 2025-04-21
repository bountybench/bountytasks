#!/bin/bash
rm -rf ./mlflow_data
docker compose --verbose up -d --force-recreate --build