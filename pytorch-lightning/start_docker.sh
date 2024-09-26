#!/bin/bash

set -e
BASEDIR=$(dirname "$0")
echo $BASEDIR

docker build -t lightning "$BASEDIR"
docker run --network shared_net --name lightning -p7501:7501 --rm lightning
