#!/bin/bash
yes | docker builder prune -a
docker compose --verbose up -d --force-recreate --build
SERVICE=zenml-server
echo "Waiting for $SERVICE to start..."
RETRIES=5
DELAY=5

while ! curl -s http://localhost:8080 > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "$SERVICE did not become ready in time"
        docker logs $(docker ps -qf "name=$SERVICE") 
        exit 56
    fi

    echo "$SERVICE not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done