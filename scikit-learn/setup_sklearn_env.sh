#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Define paths
REPO_DIR=$(pwd)
VENV_DIR="$REPO_DIR/sklearn-env"
PYTHON="$VENV_DIR/bin/python"

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ]; then
    echo "[ERROR] This script must be run from the Scikit-Learn repository root."
    exit 1
fi

# --------------------- MACOS COMPILER FIXES ---------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "[INFO] Configuring macOS compiler settings..."

    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        echo "[INFO] Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install llvm and libomp for OpenMP support
    brew install llvm libomp

    # Determine libomp prefix based on architecture
    if [[ $(uname -m) == "arm64" ]]; then
        OMP_PREFIX="/opt/homebrew/opt/libomp"
    else
        OMP_PREFIX="/usr/local/opt/libomp"
    fi

    # Get llvm prefix from Homebrew
    LLVM_PREFIX=$(brew --prefix llvm)

    # Prepend llvm to PATH so that the brewed clang is used instead of /usr/bin/clang
    export PATH="${LLVM_PREFIX}/bin:$PATH"

    # Set compiler environment variables to use llvm's clang and clang++
    export CC="${LLVM_PREFIX}/bin/clang"
    export CXX="${LLVM_PREFIX}/bin/clang++"

    # Set compiler flags to enable OpenMP support
    export CPPFLAGS+=" -Xpreprocessor -fopenmp"
    export CFLAGS+=" -I${OMP_PREFIX}/include -I${LLVM_PREFIX}/include"
    export CXXFLAGS+=" -I${OMP_PREFIX}/include -I${LLVM_PREFIX}/include"
    export LDFLAGS+=" -L${OMP_PREFIX}/lib -L${LLVM_PREFIX}/lib -lomp"
fi
# ----------------------------------------------------------------

# Set up virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "[INFO] Creating virtual environment 'sklearn-env'..."
    python3 -m venv "$VENV_DIR"
    echo "[SUCCESS] Virtual environment 'sklearn-env' created at $VENV_DIR"
else
    echo "[INFO] Using existing virtual environment at $VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install dependencies
echo "[INFO] Installing required dependencies..."
pip install --upgrade pip
pip install numpy scipy cython meson-python ninja pytest

# Build Scikit-Learn from source with verbose output
echo "[INFO] Building Scikit-Learn from source..."
echo "[DEBUG] Using these compiler flags:"
echo "CC: $CC, CXX: $CXX"
echo "CFLAGS: $CFLAGS"
echo "LDFLAGS: $LDFLAGS"

pip install --no-build-isolation --editable . --verbose

# Verify installation and OpenMP support
echo "[INFO] Verifying Scikit-Learn installation..."
python -c "from sklearn import config; print('\nBuild configuration:', config); config.show()"

# Clean up environment variables
unset CC CXX CPPFLAGS CFLAGS CXXFLAGS LDFLAGS

echo "[SUCCESS] Setup completed! OpenMP enabled for macOS."
