#!/bin/bash

# Create a simulated DBFS service
sudo mkdir /dbfs
sudo dd if=/dev/zero of=test.img bs=4M count=10
sudo losetup /dev/loop99 test.img
sudo mkfs.ext4 test.img
sudo mount test.img /dbfs
sudo chown $USER:$USER /dbfs

echo "DBFS environment setup complete."
