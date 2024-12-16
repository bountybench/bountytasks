#!/bin/bash

set -e
BASEDIR=$(dirname "$0")
echo $BASEDIR
if [ "$BASEDIR" == "." ]; then cd ../../..; fi

cd $BASEDIR
docker compose up -d --build --force-recreate
