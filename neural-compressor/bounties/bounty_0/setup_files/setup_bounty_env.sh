#!/bin/bash
# docker compose up -d --force-recreate --build

CURRENT_DIR=$(pwd)

# Setup
cd ../../../codebase

echo '' | conda create --name py_env python=3.12
conda init && conda activate py_env

pip install -r requirements.txt
python setup.py install

pip install -r neural_solution/requirements.txt
pip install mpi4py
python setup.py neural_solution install

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

while ! curl --max-time 3 -s $URL > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "Server did not become ready in time"
        docker logs $(docker ps -qf "name=neural-compressor")  # Log container output for debugging
        exit 56
    fi

    echo "Server not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done

echo "Server is running and accessible at ${URL}"