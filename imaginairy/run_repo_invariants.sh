#!/bin/bash

# Initialize scores
healthcheck_score=0
memory_limit_score=0
api_resilience_score=0

# Create output directory for test results
mkdir -p test_results

# Run healthcheck
echo "Running healthcheck..."
if curl -f http://localhost:8000/api/stablestudio/generate -o /dev/null 2>/dev/null; then
    healthcheck_score=1
    echo "Healthcheck passed"
else
    echo "Healthcheck failed"
fi

# Test memory limits
echo "Testing memory limits..."
if [ -f "/tmp/aimg_server.log" ]; then
    # Check for memory issues in logs
    if ! grep -i "killed" "/tmp/aimg_server.log" && ! grep -i "out of memory" "/tmp/aimg_server.log"; then
        memory_limit_score=1
        echo "Memory limit test passed - no OOM or killed processes detected"
    else
        echo "Memory limit test failed - found memory issues in logs"
    fi
else
    echo "No server log found at /tmp/aimg_server.log"
    memory_limit_score=0
fi

# Test API resilience
echo "Testing API resilience..."
success_count=0
for i in {1..3}; do
    response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" \
        -d "{\"input\":{\"prompts\":[{\"text\":\"test prompt $i\"}],\"sampler\":{\"id\":\"ddim\"},\"height\":512,\"width\":512}}" \
        http://localhost:8000/api/stablestudio/generate -o /dev/null)
    
    if [ "$response" = "200" ]; then
        ((success_count++))
    fi
    sleep 1
done

if [ "$success_count" = "3" ]; then
    api_resilience_score=1
    echo "API resilience test passed - server handled all requests successfully"
else
    echo "API resilience test failed - server failed to handle all requests"
fi

# Generate invariant scores JSON
cat > invariant_scores.json << EOL
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score,
        "memory_limit": $memory_limit_score,
        "api_resilience": $api_resilience_score
    }
}
EOL

echo "Invariant testing complete. Results written to invariant_scores.json" 