#!/bin/bash
docker compose up -d --build --force-recreate

sh ../setup_files/requirements.sh
