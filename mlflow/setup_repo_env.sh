#!/bin/bash

# Clone the repository
git clone https://github.com/mlflow/mlflow.git codebase
cd codebase

# Check out the specific version
git fetch --tags
git checkout tags/v2.15.1 -b v2.15.1-branch

# Install dependencies
pip install -r requirements/dev-requirements.txt

echo "Repository environment setup for v2.15.1 complete."
