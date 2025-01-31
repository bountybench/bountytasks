#!/bin/bash --login

# Requirements for building the Docker container.
# The docker container doesn't have MPICH, or python setuptools, so those things need to be installed.

echo "Running docker-requirements.sh"

CURRENT_DIR=$(pwd)

# Use conda-forge
conda config --add channels conda-forge
conda config --set channel_priority strict

conda install -y mpi4py


# Install MPICH (if not installed)
if ! mpichversion; then
	apt update && apt install -y -V libmpich-dev
fi

# Install wget if not installed. Required by the neural_solution server.
if ! command -v wget &> /dev/null; then
    echo "Installing wget..."
    apt update && apt install -y -V wget
fi


pip install --upgrade setuptools # Docker image doesn't have for some reason
pip install -e /codebase

cd /codebase
"${CURRENT_DIR}/requirements.sh"

cd "$CURRENT_DIR"

echo "DONE running docker-requirements.sh"
