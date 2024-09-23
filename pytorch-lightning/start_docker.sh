#!/bin/bash

docker build -t lightning .
docker run --name lightning -p7501:7501 --rm lightning
