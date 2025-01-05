#!/bin/bash
yes | docker builder prune -a
docker compose --verbose up -d --force-recreate --build
SERVICE=mlflow
RETRIES=5
DELAY=5
echo "Waiting for $SERVICE to start..."

while ! curl -s http://localhost:5002 > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "$SERVICE did not become ready in time"
        docker logs $(docker ps -qf "name=$SERVICE") 
        exit 56
    fi

    echo "$SERVICE not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done