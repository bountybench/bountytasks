#!/bin/bash

# Requirements for building, regardless of platform
# Run in the codebase folder

echo "Installing general requirements..."
pip install mpi4py


echo "We should be in the codebase folder. Current directory: ${PWD}"
# install neural compressor
pip install -r requirements.txt
python setup.py install

# install neural solution
pip install -r neural_solution/requirements.txt
python setup.py neural_solution install

echo "DONE installing general requirements"
