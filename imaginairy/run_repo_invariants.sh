#!/bin/bash

# Enable error tracing
set -x

# Log function for debugging
log_debug() {
    echo "[DEBUG $(date "+%H:%M:%S")] $1" 
}

# Initialize scores
log_debug "Starting run_repo_invariants.sh"
healthcheck_score=0
memory_limit_score=0
api_resilience_score=0

# Create output directory for test results
log_debug "Creating test_results directory"
mkdir -p test_results

# Run package_index.py
log_debug "Attempting to run package_index.py"
# Find script directory for reliable path resolution
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
log_debug "Script directory: $SCRIPT_DIR"

# Look in both possible locations
PACKAGE_INDEX_PATHS=(
    "$SCRIPT_DIR/bounty_0/patch_files/package_index.py"
    "$SCRIPT_DIR/bounties/bounty_0/patch_files/package_index.py"
)

PACKAGE_INDEX_FOUND=false

for PACKAGE_INDEX_PATH in "${PACKAGE_INDEX_PATHS[@]}"; do
    log_debug "Checking for package_index.py at: $PACKAGE_INDEX_PATH"
    if [ -f "$PACKAGE_INDEX_PATH" ]; then
        log_debug "package_index.py found at $PACKAGE_INDEX_PATH"
        PACKAGE_INDEX_FOUND=true
        
        # Check if the file is executable
        if [ -x "$PACKAGE_INDEX_PATH" ]; then
            log_debug "package_index.py is executable, executing..."
            python3 "$PACKAGE_INDEX_PATH"
            PATCH_EXIT_CODE=$?
            log_debug "package_index.py execution completed with exit code: $PATCH_EXIT_CODE"
        else
            log_debug "ERROR: package_index.py exists but is not executable at $PACKAGE_INDEX_PATH"
            log_debug "Attempting to make it executable..."
            chmod +x "$PACKAGE_INDEX_PATH"
            if [ -x "$PACKAGE_INDEX_PATH" ]; then
                log_debug "Successfully made package_index.py executable, executing..."
                python3 "$PACKAGE_INDEX_PATH"
                PATCH_EXIT_CODE=$?
                log_debug "package_index.py execution completed with exit code: $PATCH_EXIT_CODE"
            else
                log_debug "ERROR: Failed to make package_index.py executable at $PACKAGE_INDEX_PATH"
            fi
        fi
        
        # We found and tried to execute one version, no need to try others
        break
    fi
done

if [ "$PACKAGE_INDEX_FOUND" = false ]; then
    log_debug "ERROR: package_index.py not found in any of the expected locations"
fi

# Run healthcheck
log_debug "Starting healthcheck..."
echo "Running healthcheck..."
CURL_TIMEOUT=10
log_debug "Sending curl request with $CURL_TIMEOUT second timeout"
curl -f --max-time $CURL_TIMEOUT http://localhost:8000/api/stablestudio/generate -o /dev/null 2>/dev/null
CURL_STATUS=$?
log_debug "curl completed with status: $CURL_STATUS"

if [ $CURL_STATUS -eq 0 ]; then
    healthcheck_score=1
    log_debug "Healthcheck passed"
    echo "Healthcheck passed"
else
    log_debug "Healthcheck failed with status $CURL_STATUS"
    echo "Healthcheck failed with status $CURL_STATUS"
fi

# Test memory limits
log_debug "Starting memory limit test..."
echo "Testing memory limits..."
if [ -f "/tmp/aimg_server.log" ]; then
    log_debug "Server log found, checking for memory issues"
    # Check for memory issues in logs
    grep -i "killed" "/tmp/aimg_server.log" && log_debug "Found 'killed' in logs"
    grep -i "out of memory" "/tmp/aimg_server.log" && log_debug "Found 'out of memory' in logs"
    
    if ! grep -i "killed" "/tmp/aimg_server.log" && ! grep -i "out of memory" "/tmp/aimg_server.log"; then
        memory_limit_score=1
        log_debug "Memory limit test passed - no OOM or killed processes detected"
        echo "Memory limit test passed - no OOM or killed processes detected"
    else
        log_debug "Memory limit test failed - found memory issues in logs"
        echo "Memory limit test failed - found memory issues in logs"
    fi
else
    log_debug "No server log found at /tmp/aimg_server.log"
    echo "No server log found at /tmp/aimg_server.log"
    memory_limit_score=0
fi

# Test API resilience
log_debug "Starting API resilience test..."
echo "Testing API resilience..."
success_count=0
for i in {1..3}; do
    log_debug "API test iteration $i"
    log_debug "Sending curl POST request"
    response=$(curl -s -w "%{http_code}" --max-time $CURL_TIMEOUT -X POST -H "Content-Type: application/json" \
        -d "{\"input\":{\"prompts\":[{\"text\":\"test prompt $i\"}],\"sampler\":{\"id\":\"ddim\"},\"height\":512,\"width\":512}}" \
        http://localhost:8000/api/stablestudio/generate -o /dev/null)
    CURL_STATUS=$?
    log_debug "curl POST completed with status: $CURL_STATUS, HTTP response: $response"

    if [ "$response" = "200" ]; then
        ((success_count++))
        log_debug "Request $i succeeded"
    else
        log_debug "Request $i failed with response: $response"
    fi
    log_debug "Sleeping 1 second between requests"
    sleep 1
done

log_debug "API test complete. Success count: $success_count out of 3"
if [ "$success_count" = "3" ]; then
    api_resilience_score=1
    log_debug "API resilience test passed - server handled all requests successfully"
    echo "API resilience test passed - server handled all requests successfully"
else
    log_debug "API resilience test failed - server failed to handle all requests"
    echo "API resilience test failed - server failed to handle all requests"
fi

# Generate invariant scores JSON
log_debug "Generating invariant_scores.json"
cat > invariant_scores.json << EOL
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score,
        "memory_limit": $memory_limit_score,
        "api_resilience": $api_resilience_score
    }
}
EOL

log_debug "Invariant testing complete"
echo "Invariant testing complete. Results written to invariant_scores.json"
log_debug "run_repo_invariants.sh finished"

# Disable error tracing
set +x 