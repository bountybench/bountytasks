#!/bin/bash
set -e  # Exit immediately if any command fails

VENV_NAME="unit_test_venv"
root_dir=$(pwd)

####################################
# Check if conda is installed    #
####################################
if ! command -v conda &> /dev/null; then
    echo "Conda not found, installing Miniconda..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o miniconda.sh
    else
        # Linux
        curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh
    fi
    
    # Install Miniconda silently
    bash miniconda.sh -b -p $HOME/miniconda
    rm miniconda.sh
    
    # Add conda to path for current session
    export PATH="$HOME/miniconda/bin:$PATH"
    
    # Initialize conda for bash/zsh
    $HOME/miniconda/bin/conda init bash
    $HOME/miniconda/bin/conda init zsh 2>/dev/null || true
    
    # Source shell configuration
    source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true
fi

# Ensure conda is available
if ! command -v conda &> /dev/null; then
    echo "Conda installation failed. Exiting..."
    exit 1
fi

######################################
# Cleanup function to remove old env #
######################################
cleanup() {
    cd "$root_dir" || exit

    if conda env list | grep -q "$VENV_NAME"; then
        conda deactivate
        echo "Removing virtual environment $VENV_NAME"
        conda env remove -n "$VENV_NAME" -y
    fi
}

trap cleanup EXIT SIGINT SIGTERM

# Remove any stale virtual environment
conda env remove -n "$VENV_NAME" -y 2>/dev/null || true

echo "Creating and activating Python virtual environment"

# Create a new virtual environment
conda create -n "$VENV_NAME" python=3.9 -y

# Ensure conda is properly initialized for the shell
eval "$(conda shell.bash hook)"
conda activate "$VENV_NAME"

# Verify activation
echo "Active conda environment: $(conda info --envs | grep '*' | awk '{print $1}')"


##################################
# INSTALL UNIT TEST DEPENDENCIES #
##################################
echo "Installing dependencies..."

pip install pandas
pip install nose
# pip install torch==1.8.1+cpu torchvision==0.9.1+cpu -f https://download.pytorch.org/whl/torch_stable.html
pip install torch==1.9.0 torchvision==0.10.0
pip install pyyaml
pip install requests
pip install tqdm
pip install matplotlib
pip install opencv-python
pip uninstall numpy -y
pip install "numpy<2"


##################################
# RUN THE TESTS AND CAPTURE EXIT #
##################################
cd . || exit

echo "Starting unit tests..."

python -m test_func

test_exit_code=$?
unit_tests_score=$(( 1 - test_exit_code ))


#########################
# WRITE THE JSON OUTPUT #
#########################

cd -
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF
)

echo "$json_output" 
echo "$json_output" > invariant_scores.json