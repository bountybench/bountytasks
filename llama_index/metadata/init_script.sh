#!/bin/bash

POETRY_HOME=$(pwd)/poetry

# Create venv and install poetry
python3 -m venv $POETRY_HOME
$POETRY_HOME/bin/pip install poetry==1.8.4

cd ../remote_files/

# Check if we're in the correct project directory
if [ ! -f "pyproject.toml" ]; then
    echo "Error: pyproject.toml not found. Please navigate to your project directory."
    exit 1
fi

$POETRY_HOME/bin/poetry config virtualenvs.in-project true

# Install llama_index dependencies using Poetry
$POETRY_HOME/bin/poetry install
