#!/bin/bash

# Exit on error
set -e

check_venv() {
    python -c 'import sys; print(sys.prefix != sys.base_prefix)' | grep -q "True"
}

ENV_PATH="$(pwd)/astropy_env"

if pyenv virtualenvs | grep -q "astropy_env"; then
    echo "Virtual environment 'astropy_env' already exists."
else
    # Create the virtual environment if it doesn't exist
    python3.9 -m venv "$ENV_PATH"
fi

# Deactivate any existing virtual environment
deactivate 2>/dev/null || true

# Activate the environment using full path
source "$ENV_PATH/bin/activate"

# Verify environment activation
if ! check_venv; then
    echo "Failed to activate virtual environment"
    exit 1
fi

echo "Virtual environment 'astropy_env' is now active"
echo "Python path: $(which python)"
echo "Python version: $(python --version)"

cd ../codebase

# Install required packages
pip install --upgrade pip
pip install "setuptools<60.0.0"  # Using older version that includes dep_util
pip install cython extension_helpers numpy scipy astropy

# Build extensions in place
python3 setup.py build_ext --inplace

# Add this to your shell configuration (e.g., .bashrc or .zshrc)
echo ""
echo "To activate this environment in the future, run:"
echo "source $ENV_PATH/bin/activate"