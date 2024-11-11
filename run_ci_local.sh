#!/bin/bash

# Define color codes
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Define message prefixes
INFO="${CYAN}[INFO]${RESET}"
SUCCESS="${GREEN}[SUCCESS]${RESET}"
ERROR="${RED}[ERROR]${RESET}"
WARNING="${YELLOW}[WARNING]${RESET}"

print_header() {
    local color="$1"
    local message="$2"
    echo -e "${color}========== ${message} ==========${RESET}"
}

if [[ $# -lt 1 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Usage: ./run_ci_local.sh '<path-to-bounty>' [--patch]"
    exit 1
fi

bounty_dir="${1%/}"
repo_dir=$(dirname "$(dirname "$bounty_dir")")

# Check if bounty_dir follows the expected pattern (bounty_ + number)
if [[ ! "${bounty_dir}" =~ /bounty_[0-9]+$ ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} The path to bounty should follow the pattern '<repo_dir>/metadata/bounty_<number>' (e.g., lunary/metadata/bounty_0)"
    exit 1
fi

patch_mode=false

# Check for patch flag
if [[ "$2" == "--patch" ]]; then
    patch_mode=true
    echo -e "${INFO} Patch mode enabled."
fi

# Get vulnerable commit from bounty metadata
bounty_metadata_file="${bounty_dir}/bounty_metadata.json"
if [[ ! -f "$bounty_metadata_file" ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} bounty_metadata.json not found at ${bounty_metadata_file}"
    exit 1
fi

vulnerable_commit=$(jq -r '.vulnerable_commit' "$bounty_metadata_file")
if [[ -z "$vulnerable_commit" || "$vulnerable_commit" == "null" ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Could not find vulnerable_commit in bounty metadata"
    exit 1
fi

# Checkout the vulnerable commit
print_header "$CYAN" "CHECKOUT VULNERABLE COMMIT"
echo -e "${INFO} Checking out the vulnerable commit: ${vulnerable_commit}"
cd "${repo_dir}/codebase"
git checkout "$vulnerable_commit"
checkout_status=$?
cd -

if [[ $checkout_status -ne 0 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Failed to checkout vulnerable commit ${vulnerable_commit}"
    exit 1
fi

# Find exploit.sh and verify.sh recursively
exploit_script=$(find "${bounty_dir}" -type f -name "exploit.sh" | head -n 1)
verify_script=$(find "${bounty_dir}" -type f -name "verify.sh" | head -n 1)

if [[ -z "$exploit_script" ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Could not find exploit.sh in ${bounty_dir}"
    exit 1
fi

if [[ -z "$verify_script" ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Could not find verify.sh in ${bounty_dir}"
    exit 1
fi

# Store the directories for later use
exploit_dir=$(dirname "$exploit_script")
verify_dir=$(dirname "$verify_script")

print_header "$CYAN" "CHECKING IF EXPLOIT AND VERIFY SCRIPTS EXIST"
echo -e "${SUCCESS} Found exploit script at: ${exploit_script}"
echo -e "${SUCCESS} Found verify script at: ${verify_script}"

container_name="cybench"
image_name="cybench/cybounty:latest"
network_name="shared_net"

# Function to execute stop_docker.sh if it exists
execute_stop_docker() {
    if [[ -f "${repo_dir}/stop_docker.sh" ]]; then
        print_header "$CYAN" "EXECUTE STOP_DOCKER.SH"
        echo -e "${INFO} Executing stop_docker.sh script for the task"
        cd "${repo_dir}"
        "./stop_docker.sh"
        cd -
    fi
}

cleanup() {
    print_header "$CYAN" "CLEANUP PROCESS"
    echo -e "${INFO} Running cleanup process..."
    cd "${repo_dir}/codebase"
    git clean -fdx
    git checkout main  --force
    cd -
    execute_stop_docker
}

# Set trap to ensure cleanup runs on exit or error
trap cleanup EXIT

# Create shared network if it doesn't exist
if ! docker network ls | grep -q "${network_name}"; then
    print_header "$CYAN" "DOCKER NETWORK CREATION"
    echo -e "${INFO} Creating Docker network: ${network_name}"
    docker network create "${network_name}"
fi

# Make scripts executable
chmod +x "$exploit_script" "$verify_script" "${repo_dir}/metadata/requirements.sh"

# Step 1: Run start_docker.sh from local machine
if [[ -f "${repo_dir}/start_docker.sh" ]]; then
    print_header "$CYAN" "EXECUTE START_DOCKER.SH"
    echo -e "${INFO} Executing start_docker.sh script for the task"
    cd "${repo_dir}"
    "./start_docker.sh"
    cd -
else
    print_header "$YELLOW" "WARNING"
    echo -e "${WARNING} start_docker.sh not found in ${repo_dir}"
fi

# Exploit mode flow
print_header "$CYAN" "RUNNING VERIFY SCRIPT BEFORE EXPLOIT"
initial_log=$(cd "${verify_dir}" && ./verify.sh)
initial_status=$?

if [[ ${initial_status} -eq 0 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Running verify script before exploit should fail (return 1)"
    echo -e "${ERROR} ${initial_log}"
    exit 1
fi

echo -e "${INFO} ${initial_log}\n"


echo -e "${SUCCESS} Initial verification failed as expected. Running exploit.sh..."
print_header "$CYAN" "RUNNING EXPLOIT SCRIPT"

# Run exploit.sh inside the Docker container (with IS_CI_RUN set to true)
exploit_log=$(docker run \
    --name "${container_name}" \
    --rm \
    -it \
    --pull always \
    --privileged \
    --network "${network_name}" \
    --cgroupns host \
    -v "$(pwd)":/app \
    "${image_name}" \
    /bin/bash -c "cd '${repo_dir}/metadata' && bash requirements.sh && cd - && cd '${exploit_dir}' && bash exploit.sh true")

print_header "$CYAN" "EXPLOIT LOG"
echo -e "${INFO} ${exploit_log}\n"
execution_output=$(echo "${exploit_log}" | tail -n 1 | tr -d '[:space:]')

# Run final verify.sh directly on the local machine
print_header "$CYAN" "RUNNING VERIFY SCRIPT AFTER EXPLOIT"
final_log=$(cd "${verify_dir}" && ./verify.sh)
final_status=$?

if [[ ${final_status} -ne 0 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Verify script after exploit should succeed (return zero) after exploit but it returned ${final_status}"
    print_header "$CYAN" "VERIFY SCRIPT LOG"
    echo -e "${INFO} ${final_log}\n"
    exit 1
fi

echo -e "${INFO} ${final_log}\n"

print_header "$GREEN" "EXPLOIT MODE SUCCEEDED"
echo -e "${SUCCESS} Verify script after exploit completed successfully."

# Clean untracked files in codebase before patch test
cd "${repo_dir}/codebase"
git reset --hard "$vulnerable_commit"
cd -

if [[ "$patch_mode" == true ]]; then
    print_header "$CYAN" "APPLYING PATCH"
    patched_bounty_dir="${repo_dir}/metadata/$(basename "$bounty_dir")"

    # Apply the patches
    bounty_metadata="$patched_bounty_dir/bounty_metadata.json"
    if [[ -f "$bounty_metadata" ]]; then
        patch_pairs=$(jq -r '.patch | to_entries[] | "\(.key) \(.value)"' "$bounty_metadata")

        echo -e "${INFO} Applying patches for $patched_bounty_dir"
        while read -r source_file target_file; do
            target_dir=$(dirname "$target_file")
            if [ ! -d "$repo_dir/$target_dir" ]; then
                echo -e "${INFO} Creating directory $repo_dir/$target_dir"
                mkdir -p "$repo_dir/$target_dir"
            fi

            echo -e "${INFO} Copying $patched_bounty_dir/$source_file to $repo_dir/$target_file"
            cp "$patched_bounty_dir/$source_file" "$repo_dir/$target_file"
        done <<< "$patch_pairs"
    else
        print_header "$YELLOW" "WARNING"
        echo -e "${WARNING} No bounty_metadata.json found, skipping patch application."
    fi

    if [[ -f "${repo_dir}/start_docker.sh" ]]; then
        print_header "$CYAN" "EXECUTE START_DOCKER.SH AFTER PATCH"
        echo -e "${INFO} Executing start_docker.sh script for the task after patching"
        cd "${repo_dir}"
        "./start_docker.sh"
        cd -
    else
        print_header "$YELLOW" "WARNING"
        echo -e "${WARNING} start_docker.sh not found in ${repo_dir}"
    fi

    print_header "$CYAN" "RUNNING EXPLOIT.SH"
    log=$(docker run \
        --name "${container_name}" \
        --rm \
        -it \
        --pull always \
        --privileged \
        --network "${network_name}" \
        --cgroupns host \
        -v "$(pwd)":/app \
        "${image_name}" \
        /bin/bash -c "cd '${repo_dir}/metadata' && bash requirements.sh && cd - && cd '${exploit_dir}' && bash exploit.sh true")

    print_header "$CYAN" "EXPLOIT LOG AFTER PATCH"
    echo -e "${INFO} Log:\n ${log}"
    execution_output=$(echo "${log}" | tail -n 1 | tr -d '[:space:]')

    print_header "$CYAN" "VERIFYING AFTER PATCH"
    echo -e "${INFO} Running verify.sh after patch..."
    final_log=$(cd "${verify_dir}" && ./verify.sh)
    final_status=$?



    if [[ ${final_status} -eq 0 ]]; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} Verify script should fail (return 1) after patch, but it returned ${final_status}"
        echo -e "${ERROR} ========= Error log ========= \n\n ${final_log}"
        exit 1
    fi

    echo -e "${INFO} ${final_log}\n"

    print_header "$GREEN" "PATCH MODE SUCCEEDED"
    echo -e "${SUCCESS} Patch completed successfully."
fi

print_header "$GREEN" "CI SUCCEEDED"
echo -e "${SUCCESS} Successfully passing CI locally."