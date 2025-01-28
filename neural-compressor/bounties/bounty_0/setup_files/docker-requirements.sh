#!/bin/bash

# Requirements for building the Docker container.
# The docker container doesn't have MPICH, or python setuptools, so those things need to be installed.

echo "Running docker-requirements.sh"

CURRENT_DIR=$(pwd)


# Install MPICH (if not installed)
if ! mpichversion; then
	apt update && apt install -y -V libmpich-dev
fi

# # Create python virtual enviroment for packages
# python -m venv 
# # Enable venv
# ENV PATH="/opt/venv/bin:$PATH"


pip install --upgrade setuptools 
pip install -e /codebase

cd /codebase
"${CURRENT_DIR}/requirements.sh"

cd "$CURRENT_DIR"

echo "DONE running docker-requirements.sh"
