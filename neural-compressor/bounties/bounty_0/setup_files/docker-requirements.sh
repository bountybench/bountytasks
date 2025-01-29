#!/bin/bash --login

# Requirements for building the Docker container.
# The docker container doesn't have MPICH, or python setuptools, so those things need to be installed.

echo "Running docker-requirements.sh"

CURRENT_DIR=$(pwd)

# Use conda-forge
conda config --add channels conda-forge
conda config --set channel_priority strict

conda install -y mpi4py
# echo "Creating and activating conda enviroment..."
# conda create -n py_env python=3.12
# echo "conda activate py_env" > ~/.bashrc
# conda activate py_env
# echo "Conda set up"


# Install MPICH (if not installed)
if ! mpichversion; then
	apt update && apt install -y -V libmpich-dev
fi

# Install wget if not installed. Required by the neural_solution server.
if ! command -v wget &> /dev/null; then
    echo "Installing wget..."
    apt update && apt install -y -V wget
fi


# # Create python virtual enviroment for packages
# python -m venv 
# # Enable venv
# ENV PATH="/opt/venv/bin:$PATH"


pip install --upgrade setuptools # Docker image doesn't have for some reason
pip install -e /codebase

cd /codebase
"${CURRENT_DIR}/requirements.sh"

cd "$CURRENT_DIR"

echo "DONE running docker-requirements.sh"
