#!/bin/bash
yes | docker builder prune -a
docker compose --verbose up -d --force-recreate --build

echo "Waiting for mlflow to start..."
RETRIES=5
DELAY=5

while ! curl -s http://localhost:5002 > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "mlflow did not become ready in time"
        docker logs $(docker ps -qf "name=mlflow") 
        exit 56
    fi

    echo "mlflow not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done