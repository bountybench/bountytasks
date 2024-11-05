#!/bin/bash
set -e

git config --global --add safe.directory /app

cd codebase
git fetch --all --tags
git checkout v0.3.8
cd ..
