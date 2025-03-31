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

validate_schema() {
    local project_root="$1"
    local bounty_path="$2"
    local bounty_number=$(basename "$bounty_path" | sed 's/bounty_//')

    print_header "$CYAN" "VALIDATING PROJECT SCHEMA"

    # Check project root structure
    local required_paths=(
        "codebase"
        "setup_repo_env.sh"
        "metadata.json"
        "bounties"
        "bounties/bounty_${bounty_number}"
        "bounties/bounty_${bounty_number}/bounty_metadata.json"
        "bounties/bounty_${bounty_number}/verify.sh"
        "bounties/bounty_${bounty_number}/exploit_files"
        "bounties/bounty_${bounty_number}/exploit_files/exploit.sh"
        "bounties/bounty_${bounty_number}/patch_files"
        "bounties/bounty_${bounty_number}/setup_files"
        "bounties/bounty_${bounty_number}/setup_files/setup_bounty_env.sh"
    )

    for path in "${required_paths[@]}"; do
        if [[ ! -e "${project_root}/${path}" ]]; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} Missing required path: ${path}"
            echo -e "${ERROR} Expected schema:"
            echo -e "${INFO} ├── task_dir/"
            echo -e "${INFO} │   ├── codebase/"
            echo -e "${INFO} │   ├── setup_repo_env.sh"
            echo -e "${INFO} │   ├── metadata.json"
            echo -e "${INFO} │   ├── bounties/"
            echo -e "${INFO} │   │   ├── bounty_${bounty_number}/"
            echo -e "${INFO} │   │   │   ├── bounty_metadata.json"
            echo -e "${INFO} │   │   │   ├── verify.sh"
            echo -e "${INFO} │   │   │   └── exploit_files/"
            echo -e "${INFO} │   │   │       └── exploit.sh"
            echo -e "${INFO} │   │   │   └── patch_files/"
            echo -e "${INFO} │   │   │   └── setup_files/"
            echo -e "${INFO} │   │   │       └── setup_bounty_env.sh"
            exit 1
        fi
    done

    # DOCKER HEALTH CHECK VALIDATION
    local repo_compose="${project_root}/docker-compose.yml"
    if [[ -f "$repo_compose" ]]; then
        if ! grep -q "healthcheck:" "$repo_compose"; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} No health check found in repo-level docker-compose.yml"
            echo -e "${INFO} Each docker-compose.yml file must include health checks for at least one service"
            echo -e "${INFO} Example healthcheck configuration:"
            echo -e "${INFO} services:"
            echo -e "${INFO}   app:"
            echo -e "${INFO}     image: your-image"
            echo -e "${INFO}     healthcheck:"
            echo -e "${INFO}       test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8000/health\"]"
            echo -e "${INFO}       interval: 30s"
            echo -e "${INFO}       timeout: 10s"
            echo -e "${INFO}       retries: 3"
            exit 1
        fi
    else
        # Check bounty-level compose file if no repo-level file exists
        local bounty_compose="${bounty_path}/setup_files/docker-compose.yml"
        if [[ -f "$bounty_compose" ]]; then
            if ! grep -q "healthcheck:" "$bounty_compose"; then
                print_header "$RED" "ERROR"
                echo -e "${ERROR} No health check found in bounty-level docker-compose.yml"
                echo -e "${INFO} Example healthcheck configuration:"
                echo -e "${INFO} services:"
                echo -e "${INFO}   app:"
                echo -e "${INFO}     image: your-image"
                echo -e "${INFO}     healthcheck:"
                echo -e "${INFO}       test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:8000/health\"]"
                echo -e "${INFO}       interval: 30s"
                echo -e "${INFO}       timeout: 10s"
                echo -e "${INFO}       retries: 3"
                exit 1
            fi
        fi
    fi

    echo -e "${SUCCESS} Project schema validation passed"
}

if [[ $# -lt 1 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Usage: ./run_ci_local.sh '<path-to-bounty>' [--patch] [--check-invariants]"
    exit 1
fi


execute_if_exists() {
  local script_path="$1"
  if [ -f "$script_path" ]; then
    echo "Executing $script_path"
    bash "$script_path"
  else
    echo "$script_path not found, skipping."
  fi
}

base_dir=$(pwd)

bounty_dir="$1"
repo_dir=$(dirname "$(dirname "$bounty_dir")")

shift

RUN_PATCH=false
CHECK_INVARIANTS=false

# Loop through arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --patch) RUN_PATCH=true ;;
        --check-invariants) CHECK_INVARIANTS=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Check if bounty_dir follows the expected pattern (bounty_ + number)
if [[ ! "${bounty_dir}" =~ /bounty_[0-9]+/?$ ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} The path to bounty should follow the pattern '<repo_dir>/bounties/bounty_<number>' (e.g., lunary/bounties/bounty_0)"
    exit 1
fi

validate_schema "$repo_dir" "$bounty_dir"

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

# Check if the codebase is initialized
if [ -z "$(ls -A)" ] || [ ! -e ".git" ]; then
    echo -e "${INFO} Codebase directory appears empty or uninitialized, initializing submodule..."
    git submodule update --init .
fi


git clean -fdx
git checkout "$vulnerable_commit"
checkout_status=$?
cd -


print_header "$CYAN" "EXECUTING REPO ENVIRONMENT SETUP"
cd "$repo_dir"
execute_if_exists "setup_repo_env.sh"
sleep 10
cd -

requirements_dir="${bounty_dir}/setup_files"
print_header "$CYAN" "EXECUTING BOUNTY ENVIRONMENT SETUP"
cd $requirements_dir
execute_if_exists "setup_bounty_env.sh"
sleep 10
cd -


if [[ $checkout_status -ne 0 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Failed to checkout vulnerable commit ${vulnerable_commit}"
    exit 1
fi

exploit_dir="${bounty_dir}/exploit_files"
exploit_script="${exploit_dir}/exploit.sh" 
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

verify_dir=$(dirname "$verify_script")




print_header "$CYAN" "CHECKING IF EXPLOIT AND VERIFY SCRIPTS EXIST"
echo -e "${SUCCESS} Found exploit script at: ${exploit_script}"
echo -e "${SUCCESS} Found verify script at: ${verify_script}"

container_name="cybench"
image_name="cybench/bountyagent:latest"
network_name="shared_net"

stop_docker() {
    local compose_dir="$1"  # Directory containing docker-compose.yml
    if [[ -z "$compose_dir" ]]; then
        compose_dir="${repo_dir}"  # Default to repo_dir if no path provided
    fi

    if [[ -f "${compose_dir}/docker-compose.yml" ]]; then
        print_header "$CYAN" "STOPPING DOCKER in ${compose_dir}"
        echo -e "${INFO} Running docker compose down in ${compose_dir}"
        cd "${compose_dir}"
        docker compose down -v
        cd -
    else
        echo -e "${INFO} No docker-compose.yml found in ${compose_dir}"
    fi
}



cleanup() {
    print_header "$CYAN" "CLEANUP PROCESS"
    echo -e "${INFO} Running cleanup process..."

    # guard against exits in other dirs
    cd "$base_dir"

    cd "${repo_dir}/codebase"
    git clean -fdx
    git restore .
    git checkout main  --force
    cd -
    stop_docker "${repo_dir}" 
    stop_docker "${requirements_dir}"
}

# Set trap to ensure cleanup runs on exit, system interrupt/termination
trap cleanup EXIT SIGINT SIGTERM

# Create shared network if it doesn't exist
if ! docker network ls | grep -q "${network_name}"; then
    print_header "$CYAN" "DOCKER NETWORK CREATION"
    echo -e "${INFO} Creating Docker network: ${network_name}"
    docker network create "${network_name}"
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
echo -e "${INFO} ${exploit_dir}\n"


echo -e "${SUCCESS} Initial verification failed as expected. Running exploit.sh..."
print_header "$CYAN" "RUNNING EXPLOIT SCRIPT"
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
    /bin/bash -c "cd '${exploit_dir}' && bash exploit.sh true")

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
print_header "$CYAN" "CLEANING BEFORE PATCH"
cd "${repo_dir}/codebase"
git clean -fdx
git reset --hard "$vulnerable_commit"
cd -

if [[ "$RUN_PATCH" == true ]]; then

    print_header "$CYAN" "APPLYING PATCH"
    patched_bounty_dir="${repo_dir}/bounties/$(basename "$bounty_dir")"

    # Apply the patches
    bounty_metadata="$patched_bounty_dir/bounty_metadata.json"
    if [[ -f "$bounty_metadata" ]]; then
        patch_pairs=$(jq -r '.patch | to_entries[] | "\(.key) \(.value)"' "$bounty_metadata")

        # Retrieve patch pairs from the optional "unit_test_patch" key (if present)
        unit_test_patch_pairs=$(jq -r 'if has("unit_test_patch") then .unit_test_patch | to_entries[] | "\(.key) \(.value)" else empty end' "$bounty_metadata")
        
        all_patch_pairs="${patch_pairs}"
        # If unit_test_patch_pairs is not empty, append it to all_patch_pairs
        [ -n "$unit_test_patch_pairs" ] && all_patch_pairs="${all_patch_pairs}"$'\n'"${unit_test_patch_pairs}"

        echo -e "${INFO} Applying patches for $patched_bounty_dir"
        while read -r source_file target_file; do
            target_dir=$(dirname "$target_file")
            if [ ! -d "$repo_dir/$target_dir" ]; then
                echo -e "${INFO} Creating directory $repo_dir/$target_dir"
                mkdir -p "$repo_dir/$target_dir"
            fi

            echo -e "${INFO} Copying $patched_bounty_dir/$source_file to $repo_dir/$target_file"
            cp "$patched_bounty_dir/$source_file" "$repo_dir/$target_file"
        done <<< "$all_patch_pairs"
    else
        print_header "$YELLOW" "WARNING"
        echo -e "${WARNING} No bounty_metadata.json found, skipping patch application."
    fi


    stop_docker "${repo_dir}" 
    stop_docker "${requirements_dir}"

    print_header "$CYAN" "EXECUTING REPO ENVIRONMENT SETUP"
    cd "$repo_dir"
    execute_if_exists "setup_repo_env.sh"
    sleep 10
    cd -

    requirements_dir="${bounty_dir}/setup_files"
    print_header "$CYAN" "EXECUTING BOUNTY ENVIRONMENT SETUP"
    cd $requirements_dir
    execute_if_exists "setup_bounty_env.sh"
    sleep 10
    cd -

    if [[ "$CHECK_INVARIANTS" == true ]]; then
        print_header "$CYAN" "RUN REPO INVARIANT CHECK"
        cd "$repo_dir"
        execute_if_exists "run_repo_invariants.sh"
        invariant_status=$?
        if [[ ${invariant_status} -ne 0 ]]; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} CHECK REPO INVARIANT FAIL"
            exit 1
        fi
        sleep 10
        cd -

        print_header "$CYAN" "RUN BOUNTY INVARIANT CHECK"
        cd "${bounty_dir}"
        execute_if_exists "run_bounty_invariants.sh"
        invariant_status=$?
        if [[ ${invariant_status} -ne 0 ]]; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} CHECK BOUNTY INVARIANT FAIL"
            exit 1
        fi
        sleep 10
        cd -

        python ./tests/check_invariants.py "${repo_dir}/metadata.json" "${repo_dir}/invariant_scores.json"  "${bounty_dir}/bounty_metadata.json" "${bounty_dir}/invariant_scores.json"
        invariant_status=$?
        if [[ ${invariant_status} -ne 0 ]]; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} CHECK BOUNTY INVARIANT FAIL"
            exit 1
        fi
    else
        print_header "$CYAN" "SKIP REPO INVARIANT CHECK"
        print_header "$CYAN" "SKIP BOUNTY INVARIANT CHECK"
    fi

    print_header "$CYAN" "VERIFYING BEFORE EXPLOIT"
    final_log=$(cd "${verify_dir}" && ./verify.sh)
    final_status=$?
    echo -e "${INFO} Verify script exit status: ${final_status}"



    if [[ ${final_status} -eq 0 ]]; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} Verify script should fail (return 1) after patch, but it returned ${final_status}"
        echo -e "${ERROR} ========= Error log ========= \n\n ${final_log}"
        exit 1
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
    /bin/bash -c "cd '${exploit_dir}' && bash exploit.sh true")

    print_header "$CYAN" "EXPLOIT LOG AFTER PATCH"
    echo -e "${INFO} Log:\n ${log}"
    execution_output=$(echo "${log}" | tail -n 1 | tr -d '[:space:]')

    print_header "$CYAN" "VERIFYING AFTER EXPLOIT"
    final_log=$(cd "${verify_dir}" && ./verify.sh)
    final_status=$?
    echo -e "${INFO} Verify script exit status: ${final_status}"



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