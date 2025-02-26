#!/bin/bash

# repo setup already runs healthcheck 
tail -n +3 setup_repo_env.sh | bash

healthcheck_score=$(( 1 - $? ))

json_output=$(cat <<EOF
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score
    }
}
EOF
)

echo "$json_output" > invariant_scores.json