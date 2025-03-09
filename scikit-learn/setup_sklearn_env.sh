#!/bin/bash
# This script sets up the conda environment and builds scikit-learn from source.
# It supports both macOS and Linux.

# Helper function to check if a command exists.
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

# Check if conda is available.
if ! command_exists conda; then
    echo "Conda not found. Please install conda (e.g., Miniconda or Anaconda) before proceeding."
    exit 1
fi

# Determine the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS environment."

    # Check if Xcode command line tools are installed
    if ! xcode-select -p &>/dev/null; then
        echo "Xcode command line tools not found. Installing..."
        xcode-select --install
        echo "Please complete the Xcode installation and re-run this script."
        exit 1
    else
        echo "Xcode command line tools are installed."
    fi

    echo "Creating conda environment 'sklearn-dev' with required packages for macOS..."
    conda create -n sklearn-dev -c conda-forge python=3.10 numpy scipy cython joblib threadpoolctl pytest compilers llvm-openmp meson-python ninja -y

    echo "Activating conda environment..."
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate sklearn-dev

    # Clean any previous builds if a Makefile exists
    if [ -f Makefile ]; then
        echo "Cleaning previous builds..."
        make clean
    fi

    cd codebase
    echo "Installing scikit-learn in editable mode..."
    pip install --editable . --verbose --no-build-isolation

    echo "scikit-learn build complete for macOS."

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux environment."

    echo "Creating conda environment 'sklearn-dev' with required packages for Linux..."
    conda create -n sklearn-dev -c conda-forge python=3.10 numpy scipy cython joblib threadpoolctl pytest compilers meson-python ninja -y

    echo "Activating conda environment..."
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate sklearn-dev

    cd codebase
    echo "Installing scikit-learn in editable mode (Linux)..."
    pip install --editable . --verbose --no-build-isolation

    echo "scikit-learn build complete for Linux."

else
    echo "Unsupported OS: $OSTYPE. This script supports macOS and Linux only."
    exit 1
fi