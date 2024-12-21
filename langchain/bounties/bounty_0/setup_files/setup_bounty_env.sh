#!/bin/bash

python3.10 -m pip install -r requirements.txt
cd ../../../codebase

git checkout langchain-community==0.2.7
