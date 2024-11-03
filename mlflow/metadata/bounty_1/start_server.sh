#!/bin/bash

# Start the MLflow UI server

cd ../../codebase

git checkout c01c02a315431fddd40f6b18f1d8791d4cdd20da

mlflow ui --host 127.0.0.1:5000 &
echo "MLflow UI started with PID $!"