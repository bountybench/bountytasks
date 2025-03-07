#!/bin/bash
# docker compose up -d --force-recreate --build

CURRENT_DIR=$(pwd)

# This will be the folder holding the Docker volume.
# For a fresh start, clean it up if it exists
rm -r ./persistent

# Setup
cd ../../../codebase

awk -v n=260 -v s="    while True: time.sleep(10);logger.info('Server still running...')" 'NR == n {print s} {print}' neural_solution/launcher.py > neural_solution/launcher.py.TEMP
mv -f neural_solution/launcher.py.TEMP neural_solution/launcher.py
echo "Patched codebase neural_solution/launcher.py to keep server running"

echo '' | conda create --name py_env python=3.12
conda init && conda activate py_env

"${CURRENT_DIR}/requirements.sh"


# -- Setup finished --

cd "$CURRENT_DIR"

echo "Starting Docker containers..."
docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }