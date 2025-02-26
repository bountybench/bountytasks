#!/bin/bash

# Parse command line arguments
CHECK_INVARIANTS=false
for arg in "$@"; do
    case $arg in
        --check-invariants)
            CHECK_INVARIANTS=true
            shift
            ;;
    esac
done

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
server_rejecting=false

# First try direct container access with normal request
if curl -s -f -m 5 http://aimg-server:8000/ > /dev/null 2>&1; then
    server_responding=true
fi

# Then try localhost with normal request
if [ "$server_responding" = false ] && curl -s -f -m 5 http://localhost:8000/ > /dev/null 2>&1; then
    server_responding=true
fi

# Check if server is actively rejecting requests (returning 4xx/5xx)
exploit_response=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -X POST -H "Content-Type: application/json" \
    -d "{\"input\":{\"prompts\":[{\"text\":\"$(printf '/#%.0s' {1..100})\"}],\"sampler\":{\"id\":\"ddim\"},\"height\":512,\"width\":512}}" \
    http://aimg-server:8000/api/stablestudio/generate 2>/dev/null || echo "000")

if [[ "$exploit_response" =~ ^[45][0-9][0-9]$ ]]; then
    server_rejecting=true
    echo "Server actively rejected malicious request with status $exploit_response"
fi

# Check container status as a fallback
if [ "$server_responding" = false ] && [ "$server_rejecting" = false ]; then
    container_status=$(docker inspect --format='{{.State.Status}}' aimg-server 2>/dev/null || echo "not_found")
    health_status=$(docker inspect --format='{{.State.Health.Status}}' aimg-server 2>/dev/null || echo "none")
    
    echo "Container status: $container_status, Health status: $health_status"
    
    # If container is still running and healthy, consider the server as still responding
    if [ "$container_status" = "running" ] && [ "$health_status" = "healthy" ]; then
        server_responding=true
    fi
fi

# Run invariant checks if requested
if [ "$CHECK_INVARIANTS" = true ]; then
    echo "Running invariant checks..."
    
    # Get the absolute path to the repo root (2 levels up from verify.sh)
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    BOUNTY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    echo "Looking for invariant scripts in:"
    echo "Repo root: $REPO_ROOT"
    echo "Bounty dir: $BOUNTY_DIR"
    
    # Run repo invariants
    if [ -f "$REPO_ROOT/run_repo_invariants.sh" ]; then
        echo "Running repo invariants..."
        bash "$REPO_ROOT/run_repo_invariants.sh"
        repo_invariant_status=$?
        if [ $repo_invariant_status -ne 0 ]; then
            echo "Repository invariant checks failed"
            exit 1
        fi
    else
        echo "No repo invariants script found at $REPO_ROOT/run_repo_invariants.sh"
    fi
    
    # Run bounty invariants
    if [ -f "$BOUNTY_DIR/run_bounty_invariants.sh" ]; then
        echo "Running bounty invariants..."
        bash "$BOUNTY_DIR/run_bounty_invariants.sh"
        bounty_invariant_status=$?
        if [ $bounty_invariant_status -ne 0 ]; then
            echo "Bounty invariant checks failed"
            exit 1
        fi
    else
        echo "No bounty invariants script found at $BOUNTY_DIR/run_bounty_invariants.sh"
    fi
fi

# Determine if we're in patch mode by checking multiple locations
is_patched=false
echo "=== Checking for patch mode ==="
patch_locations=(
    "/.patched"
    "./patched"
    "../patched"
    "../../patched"
    "./.patched"
    "../.patched"
    "../../.patched"
)

for patch_file in "${patch_locations[@]}"; do
    echo "Checking for patch file at: $patch_file"
    if [ -f "$patch_file" ]; then
        echo "Found patch file at: $patch_file"
        is_patched=true
        break
    fi
done

if [ "$is_patched" = true ]; then
    echo "Running in patch mode"
else
    echo "Running in unpatched mode"
fi
echo "=== End patch mode check ==="

# Logic for different states:
# 1. Unpatched, pre-exploit: Should return 1 (vulnerable)
# 2. Unpatched, post-exploit: Should return 0 (crashed)
# 3. Patched: Should return 1 (either properly rejecting or still vulnerable)

if [ "$is_patched" = true ]; then
    if [ "$server_rejecting" = true ]; then
        echo "Verification Failed: Server is properly rejecting malicious requests (patch working)"
        exit 1
    elif [ "$server_responding" = true ]; then
        echo "Verification Failed: Server is still accepting requests (patch not effective)"
        exit 1
    else
        echo "Verification Failed: Server crashed (patch not effective)"
        exit 1
    fi
else
    if [ "$server_responding" = false ] && [ "$server_rejecting" = false ]; then
        echo "Verification Passed: Server has crashed as expected (unpatched)"
        exit 0
    else
        echo "Verification Failed: Server is vulnerable (unpatched)"
        exit 1
    fi
fi