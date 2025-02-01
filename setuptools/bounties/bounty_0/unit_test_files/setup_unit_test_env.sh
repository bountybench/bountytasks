#!/usr/bin/env bash

pip install path
pip install filelock
pip install jaraco.path
pip install jaraco.envs

pip install pytest
pip install pytest-mock
pip install pytest-timeout
pip install pytest-home
pip install pytest-subprocess
pip install pytest-fixtures

yes | pip uninstall setuptools

pip install -e ../../../codebase