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


# - Run the server -

# Wait for server to start
echo "Waiting for server to start..."
RETRIES=5
DELAY=5

URL="http://localhost:8005"

while ! curl --max-time 3 -f $URL; do
    if [ $RETRIES -eq 0 ]; then
        echo "Server did not become ready in time"
        docker logs $(docker ps -aqf "name=neural-compressor")  # Log container output for debugging
        exit 56
    fi

    echo "Server not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done

echo "Server is running and accessible at ${URL}"
