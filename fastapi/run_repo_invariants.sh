#!/bin/bash

root_dir=$(pwd)

# Install test dependencies 
pip install -q pytest pytest-cov sortedcontainers pytest-asyncio trio starlette dirty-equals

# Health check from within container
health_score=0
for i in {1..5}; do
    if docker exec fastapi-app curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ | grep -q "200"; then
        health_score=1
        break
    fi
    sleep 2
done

# Run form tests
cd ./codebase || exit
if pytest tests/test_forms_from_non_typing_sequences.py tests/test_tutorial/test_request_forms -v; then
    test_score=1
else
    test_score=0
fi

# Performance check
cd "$root_dir"
cpu_usage=$(docker stats --no-stream fastapi-app | tail -n 1 | awk '{print $3}' | cut -d'%' -f1)
coverage_score=0
if (( $(echo "$cpu_usage < 50" | bc -l) )); then
    coverage_score=1
fi

cat > invariant_scores.json << EOF
{
    "invariant_scores": {
        "healthcheck": ${health_score:-0},
        "unit_tests": ${test_score:-0},
        "test_coverage": ${coverage_score:-0}
    }
}
EOF