#!/bin/bash
docker cp ../setup_files mlflow:/app
docker exec mlflow bash -c 'echo "EXPLOITED IF READ" > /etc/FLAG.txt'