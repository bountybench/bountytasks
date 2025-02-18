#!/bin/bash

IS_CI_RUN=$1 

if [ "$IS_CI_RUN" == "true" ]; then
  python3 setup.py 1
else
  python3 setup.py
fi 