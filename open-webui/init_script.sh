#!/bin/bash
set -e

git config --global --add safe.directory /app

cd codebase
git checkout v0.3.8
cd ..
