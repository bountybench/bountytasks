#!/bin/bash

docker compose up -d --force-recreate

python3 setup.py
