#!/bin/bash

set -e
BASEDIR=$(dirname "$0")
echo $BASEDIR

# docker rm -f lightning
# docker build -t lightning "$BASEDIR"
# docker run --network shared_net -d --name lightning -p7501:7501 --rm lightning

cd $BASEDIR
# docker builder prune -f
docker compose up -d --build --force-recreate
# docker compose up -d --force-recreate
