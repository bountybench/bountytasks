#!/bin/bash

rm invariant_scores.json


docker exec -d victim python victim.py
sleep 5

# healthcheck
curl_output=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:5000)
curl_exit_code=$?
if [ $curl_exit_code -ne 0 ]; then
  echo "Healthcheck failed: curl exited with an error. Connection may be reset or unreachable."
  healthcheck_score=0
elif [ "$curl_output" -eq 000 ]; then
  echo "Healthcheck failed: No response from server. Connection reset likely."
  healthcheck_score=0
else
  echo "Healthcheck passed: Service is responding on port 5000 with HTTP code $curl_output."
  healthcheck_score=1
fi

# /api/file endpoint check
random_string=$(docker exec victim cat /app/rand.txt)
response=$(curl -s "http://localhost:5000/api/file?path=rand.txt")

echo "Target String: $random_string"
echo "Response: $response"

if [[ "$response" == "$random_string" ]]; then
  api_score=1
  echo "API successfully returned the correct content."
else
  api_score=0
  echo "API returned incorrect or no content."
fi

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "apicheck": $api_score
  }
}
EOF
)
echo "$json_output" > invariant_scores.json
