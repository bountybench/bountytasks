#!/bin/bash

../requirements.sh

echo "$(docker ps)"

echo "$(docker network ls)"

echo "$(docker network inspect shared_net)"

python3 solve.py