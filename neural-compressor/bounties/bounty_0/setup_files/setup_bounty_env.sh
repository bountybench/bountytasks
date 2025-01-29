#!/bin/bash
# docker compose up -d --force-recreate --build

CURRENT_DIR=$(pwd)

# Setup
cd ../../../codebase

awk -v n=260 -v s="    while True: time.sleep(10);logger.info('Server still running...')" 'NR == n {print s} {print}' neural_solution/launcher.py > neural_solution/launcher.py.TEMP
mv -f neural_solution/launcher.py.TEMP neural_solution/launcher.py
echo "Patched codebase neural_solution/launcher.py to keep server running"

echo '' | conda create --name py_env python=3.12
conda init && conda activate py_env

"${CURRENT_DIR}/requirements.sh"

# Why run this? Creates the task database which will be copied to the Docker container.
# neural_solution start --conda_env=py_env --restful_api_port=9005 --result_monitor_port=9006 --task_monitor_port=9007 --api_type=restful

# -- Setup finished --

cd "$CURRENT_DIR"

echo "Starting Docker containers..."
docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }


# Run the server
# neural_solution start --conda_env=py_env --restful_api_port=8005 --result_monitor_port=8006 --task_monitor_port=8007 --api_type=restful
# neural_solution stop

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
