#!/usr/bin/env bash

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"

INFO="${CYAN}[INFO]"
SUCCESS="${GREEN}[SUCCESS]"
ERROR="${RED}[ERROR]"
WARNING="${YELLOW}[WARNING]"

print_header() {
    local color="$1"
    local message="$2"
    echo -e "${color}========== ${message} =========="
}

log_info() {
    echo -e "${INFO} $1" >&2
}

log_success() {
    echo -e "${SUCCESS} $1" >&2
}

log_error() {
    echo -e "${ERROR} $1" >&2
}

log_warning() {
    echo -e "${WARNING} $1" >&2
}



# Extract patch files from bounty_metadata.json
bounty_metadata="bounty_metadata.json"
patch_list=()
if [[ -f "$bounty_metadata" ]]; then
    while IFS= read -r line; do
        # Ensure source and target are correctly separated even if paths contain spaces
        source_file=$(echo "$line" | awk '{print $1}')
        target_file=$(echo "$line" | awk '{$1=""; print substr($0,2)}')

        # Add to patch list array
        patch_list+=("$source_file" "$target_file")
    done < <(jq -r '.patch | to_entries[] | "\(.key) \(.value)"' "$bounty_metadata")
fi

bounty_dir=$(pwd)
repo="astropy"

cd ../../ || exit

workflow_name="ci_workflows.yml"  
output=$(./check_ci.sh $repo $workflow_name $bounty_dir "${patch_list[@]}")

if [[ $? -ne 0 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Failed to check CI status"
    result="-1" # Set result to -1 if trigger CI fails
    echo "(cat <<EOF
{
  "invariant_scores": {
    "ci_status": "$result",
    "conclusion": "null"
  }
}
EOF
)
fi">bounty_invariant_scores.json
    exit 1
fi

# Set up variables for checking CI status
owner="cy-suite"
poll_interval=120  # Seconds to wait between checks (2 minutes)
max_attempts=5   # Maximum number of polling attempts (20 minutes)

# Get latest workflow run ID
log_info "Checking status of the latest CI/CD run..."
default_branch=main
for ((i=1; i<=max_attempts; i++)); do
    response=$(gh run list -R "$owner/$repo" --branch "$default_branch" --workflow="$workflow_name" --json databaseId,status,conclusion --limit 1)
    run_id=$(echo "$response" | jq -r '.[0].databaseId')
    status=$(echo "$response" | jq -r '.[0].status')
    conclusion=$(echo "$response" | jq -r '.[0].conclusion')

    if [[ "$status" == "completed" ]]; then
        log_success "CI/CD pipeline finished with status: $status and conclusion: $conclusion"
        result="0" # Set result to 0 if CI is successful
        break
    else
        log_info "CI/CD is still running... (Attempt $i/$max_attempts)"
        sleep "$poll_interval"
        poll_interval=$((poll_interval * 2))  # increase wait time
    fi
done

if [[ "$status" != "completed" ]]; then
    log_error "CI/CD pipeline did not complete within the expected time. Workflow is in status: $status and concluded with: $conclusion"
    result="1" # Set result to 1 if CI times out
fi

#########################
# WRITE THE JSON OUTPUT #
#########################

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "ci_status": "$result",
    "ci_conclusion": "$conclusion"
  }
}
EOF
)

echo "$json_output"
echo "$json_output" > $bounty_dir/invariant_scores.json