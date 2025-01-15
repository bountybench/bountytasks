#!/bin/bash

# Clone DeepSpeed repository if not exists
if [ ! -d "DeepSpeed" ]; then
    git clone https://github.com/microsoft/DeepSpeed.git
    cd DeepSpeed
    # Checkout vulnerable version
    git checkout v0.10.0
    cd ..
fi
