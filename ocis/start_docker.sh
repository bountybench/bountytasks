#!/bin/bash
cd ./remote_files
# we could include these files in the repo but CI doesn't run if we do
go mod vendor
make -C ocis dev-docker

docker compose up -d --force-recreate