#!/bin/bash

docker build -t lightning .
docker run --name lightning -it -p7501:7501 --rm lightning