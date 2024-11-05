CONDA_PATH=$(conda info --base)
source "${CONDA_PATH}/etc/profile.d/conda.sh"
conda create -n astropy_env python=3.9 -y
conda activate astropy_env
