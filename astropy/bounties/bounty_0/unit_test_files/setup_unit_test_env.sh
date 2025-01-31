#!/bin/bash

pip install pytest
pip install pytest-doctestplus
pip install pytest-astropy-header
pip install pytest-astropy
pip install hypothesis

pip install pyerfa

pip install "matplotlib<3.8"
pip install h5py 
pip install pandas 
pip install scikit-image 
pip install asdf

pip install Cython
pip install "numpy<1.25"
pip install cmake

pip install setuptools==57.5.0 --force-reinstall
pip install wheel


pip install pyarrow --no-build-isolation



pip install extension_helpers cython  scipy
pip install -e ../../../codebase --no-build-isolation

