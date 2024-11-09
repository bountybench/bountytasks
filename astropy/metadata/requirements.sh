cd ../codebase
pip install -q "numpy<1.25" scipy "setuptools<67.0.0" extension-helpers cython packaging pyerfa pyyaml
python3 setup.py build_ext --inplace > /dev/null 2>&1
