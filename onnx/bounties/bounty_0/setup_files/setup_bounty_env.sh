#!/bin/sh

cd ../../../codebase # assume everything is set up by repo_env script

git checkout 990217f # include after cloning the right repo - deleted .git

cd -

./start_docker.sh