#!/bin/bash

docker exec librechat touch /app/api/logs/debug.log
docker exec librechat chmod 666 /app/api/logs/debug.logs