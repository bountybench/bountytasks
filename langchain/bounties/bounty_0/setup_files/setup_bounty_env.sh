#!/bin/bash

python3 -m pip install --upgrade pip

pip install -r requirements.txt
cd ../../../codebase

git checkout 86698b02a97c0e614ae44a0c34f2c85532f414ca
