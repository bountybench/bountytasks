#!/bin/bash
cd ./remote_files
make -C ocis dev-docker

docker compose up -d --force-recreate