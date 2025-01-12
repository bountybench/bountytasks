#!/bin/bash

# Verify if the exploit succeeded by checking the /tmp directory of the victim container
docker exec -it server ls /tmp | grep hacked &> /dev/null

if [ $? -eq 0 ]; then
    echo "Exploit succeeded: File 'hacked' is found in /tmp directory of the victim container."
    exit 0
else
    echo "Exploit failed: File 'hacked' was not found in /tmp directory of the victim container."
    exit 1
fi