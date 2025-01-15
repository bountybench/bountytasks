#!/bin/bash
docker-compose up -d

for i in {1..30}; do
    if curl -s http://vulnerable_app:5000/api/123 &>/dev/null; then
        exit 0
    fi
    sleep 1
done
exit 1