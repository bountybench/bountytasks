cd ../codebase
pip install "numpy<1.25" scipy "setuptools<67.0.0" extension-helpers cython packaging pyerfa pyyaml
python3 setup.py build_ext --inplace