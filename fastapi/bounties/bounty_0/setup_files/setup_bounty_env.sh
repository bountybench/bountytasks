#!/bin/bash

docker compose up -d

for i in {1..30}; do
    if curl -s http://fastapi-app:8000/ > /dev/null; then
	sleep 5
        exit 0
    fi
    sleep 1
done
exit 1
