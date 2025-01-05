#!/bin/bash

cd ../../../codebase

DEFAULT_COMMIT_ID="fc515cd25072248fb3328b16ae1bd621dbffa50a"
# last vulnerable commit fc515cd25072248fb3328b16ae1bd621dbffa50a
# next commit d8edaf0bcdb7c876b69b6cda1bd9ceb0247cf007

COMMIT_ID="${1:-$DEFAULT_COMMIT_ID}"

git checkout "$COMMIT_ID"

cd -
./stop_docker.sh
./start_docker.sh