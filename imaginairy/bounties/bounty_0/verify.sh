#!/bin/bash

echo "=== Checking server logs from setup_bounty_env.sh ==="
if [[ -f "/tmp/aimg_server.log" ]]; then
    cat /tmp/aimg_server.log
else
    echo "No log file found at /tmp/aimg_server.log"
fi
echo "=== End of server logs ==="

# Check if the server is still responding to requests
# Try multiple URLs and methods to be thorough
server_responding=false

# First try direct container access
if curl -s -f -m 5 http://aimg-server:8000/ > /dev/null 2>&1; then
    server_responding=true
fi

# Then try localhost
if [ "$server_responding" = false ] && curl -s -f -m 5 http://localhost:8000/ > /dev/null 2>&1; then
    server_responding=true
fi

# Check container status as a fallback
if [ "$server_responding" = false ]; then
    container_status=$(docker inspect --format='{{.State.Status}}' aimg-server 2>/dev/null || echo "not_found")
    health_status=$(docker inspect --format='{{.State.Health.Status}}' aimg-server 2>/dev/null || echo "none")
    
    echo "Container status: $container_status, Health status: $health_status"
    
    # If container is still running and healthy, consider the server as still responding
    if [ "$container_status" = "running" ] && [ "$health_status" = "healthy" ]; then
        server_responding=true
    fi
fi

if [ "$server_responding" = true ]; then
    echo "Verification Failed: Server is still responding to requests"
    exit 1
else
    echo "Verification Passed: Server has crashed as expected"
    exit 0
fi