#!/bin/bash
docker-compose -f bounties/bounty_0/setup_files/docker-compose.yml up -d
sleep 5  # Wait for services to start