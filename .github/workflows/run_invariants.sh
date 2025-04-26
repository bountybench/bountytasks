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
        "bounties/bounty_${bounty_number}/verify_files"
        "bounties/bounty_${bounty_number}/verify_files/verify.sh"
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
            echo -e "${INFO} │   │   │   ├── verify_files/"
            echo -e "${INFO} │   │   │   │   └── verify.sh"
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
    echo -e "${ERROR} Usage: ./run_ci_local.sh '<path-to-bounty>' [--patch] [--check-invariants] [--check-compatible-patches]"
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
CHECK_COMPATIBLE_PATCHES=false

# Loop through arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --patch) RUN_PATCH=true ;;
        --check-invariants) CHECK_INVARIANTS=true ;;
        --check-compatible-patches) CHECK_COMPATIBLE_PATCHES=true ;;
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

# Ensure metadata.json has a 'target_host' key of type string (empty allowed)
print_header "$CYAN" "VALIDATING TARGET_HOST KEY"

if ! jq -e '
     has("target_host") and
     (.target_host | type == "string")
   ' "${repo_dir}/metadata.json" >/dev/null
then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} 'metadata.json' must contain a top‑level 'target_host' key of type string (can be empty)"
    exit 1
else
    echo -e "${SUCCESS} 'target_host' key validated in metadata.json"
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

# Check if the codebase is initialized
if [ -z "$(ls -A)" ] || [ ! -e ".git" ]; then
    echo -e "${INFO} Codebase directory appears empty or uninitialized, initializing submodule..."
    git submodule update --init .
fi

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


if [[ "$CHECK_INVARIANTS" == true ]]; then
    print_header "$CYAN" "VALIDATING & VERIFYING INVARIANT TEST PATHS"

    # 1) Require the key
    if ! jq -e 'has("invariant_test_paths")' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' must contain an 'invariant_test_paths' key with an array of strings (e.g., \"invariant_test_paths\": [])"
        exit 1
    fi

    # 2) Validate type & contents
    if ! jq -e '
        (.invariant_test_paths | type == "array") and
        all(.invariant_test_paths[]; type == "string")
    ' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' - invariant_test_paths must be an array of strings"
        exit 1
    fi

    # 3) Existence check
    paths=$(jq -r '.invariant_test_paths[]?' "${repo_dir}/metadata.json")
    if [[ -n "$paths" ]]; then
        echo -e "${INFO} Checking paths listed in 'metadata.json'"
        while IFS= read -r p; do
            full="${repo_dir}/${p}"
            if [[ ! -e "$full" ]]; then
                print_header "$RED" "ERROR"
                echo -e "${ERROR} Path not found: ${p} (in 'metadata.json')"
                exit 1
            fi
        done <<< "$paths"
        echo -e "${SUCCESS} All invariant_test_paths in 'metadata.json' exist."
    else
        echo -e "${INFO} 'metadata.json' has an empty invariant_test_paths array, skipping existence check."
    fi

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


if [[ "$CHECK_INVARIANTS" == true ]]; then
    print_header "$CYAN" "VALIDATING & VERIFYING INVARIANT TEST PATHS"

    # 1) Require the key
    if ! jq -e 'has("invariant_test_paths")' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' must contain an 'invariant_test_paths' key with an array of strings (e.g., \"invariant_test_paths\": [])"
        exit 1
    fi

    # 2) Validate type & contents
    if ! jq -e '
        (.invariant_test_paths | type == "array") and
        all(.invariant_test_paths[]; type == "string")
    ' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' - invariant_test_paths must be an array of strings"
        exit 1
    fi

    # 3) Existence check
    paths=$(jq -r '.invariant_test_paths[]?' "${repo_dir}/metadata.json")
    if [[ -n "$paths" ]]; then
        echo -e "${INFO} Checking paths listed in 'metadata.json'"
        while IFS= read -r p; do
            full="${repo_dir}/${p}"
            if [[ ! -e "$full" ]]; then
                print_header "$RED" "ERROR"
                echo -e "${ERROR} Path not found: ${p} (in 'metadata.json')"
                exit 1
            fi
        done <<< "$paths"
        echo -e "${SUCCESS} All invariant_test_paths in 'metadata.json' exist."
    else
        echo -e "${INFO} 'metadata.json' has an empty invariant_test_paths array, skipping existence check."
    fi

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


if [[ "$CHECK_INVARIANTS" == true ]]; then
    print_header "$CYAN" "VALIDATING & VERIFYING INVARIANT TEST PATHS"

    # 1) Require the key
    if ! jq -e 'has("invariant_test_paths")' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' must contain an 'invariant_test_paths' key with an array of strings (e.g., \"invariant_test_paths\": [])"
        exit 1
    fi

    # 2) Validate type & contents
    if ! jq -e '
        (.invariant_test_paths | type == "array") and
        all(.invariant_test_paths[]; type == "string")
    ' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' - invariant_test_paths must be an array of strings"
        exit 1
    fi

    # 3) Existence check
    paths=$(jq -r '.invariant_test_paths[]?' "${repo_dir}/metadata.json")
    if [[ -n "$paths" ]]; then
        echo -e "${INFO} Checking paths listed in 'metadata.json'"
        while IFS= read -r p; do
            full="${repo_dir}/${p}"
            if [[ ! -e "$full" ]]; then
                print_header "$RED" "ERROR"
                echo -e "${ERROR} Path not found: ${p} (in 'metadata.json')"
                exit 1
            fi
        done <<< "$paths"
        echo -e "${SUCCESS} All invariant_test_paths in 'metadata.json' exist."
    else
        echo -e "${INFO} 'metadata.json' has an empty invariant_test_paths array, skipping existence check."
    fi

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


if [[ "$CHECK_INVARIANTS" == true ]]; then
    print_header "$CYAN" "VALIDATING & VERIFYING INVARIANT TEST PATHS"

    # 1) Require the key
    if ! jq -e 'has("invariant_test_paths")' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' must contain an 'invariant_test_paths' key with an array of strings (e.g., \"invariant_test_paths\": [])"
        exit 1
    fi

    # 2) Validate type & contents
    if ! jq -e '
        (.invariant_test_paths | type == "array") and
        all(.invariant_test_paths[]; type == "string")
    ' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' - invariant_test_paths must be an array of strings"
        exit 1
    fi

    # 3) Existence check
    paths=$(jq -r '.invariant_test_paths[]?' "${repo_dir}/metadata.json")
    if [[ -n "$paths" ]]; then
        echo -e "${INFO} Checking paths listed in 'metadata.json'"
        while IFS= read -r p; do
            full="${repo_dir}/${p}"
            if [[ ! -e "$full" ]]; then
                print_header "$RED" "ERROR"
                echo -e "${ERROR} Path not found: ${p} (in 'metadata.json')"
                exit 1
            fi
        done <<< "$paths"
        echo -e "${SUCCESS} All invariant_test_paths in 'metadata.json' exist."
    else
        echo -e "${INFO} 'metadata.json' has an empty invariant_test_paths array, skipping existence check."
    fi

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


if [[ "$CHECK_INVARIANTS" == true ]]; then
    print_header "$CYAN" "VALIDATING & VERIFYING INVARIANT TEST PATHS"

    # 1) Require the key
    if ! jq -e 'has("invariant_test_paths")' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' must contain an 'invariant_test_paths' key with an array of strings (e.g., \"invariant_test_paths\": [])"
        exit 1
    fi

    # 2) Validate type & contents
    if ! jq -e '
        (.invariant_test_paths | type == "array") and
        all(.invariant_test_paths[]; type == "string")
    ' "${repo_dir}/metadata.json" >/dev/null; then
        print_header "$RED" "ERROR"
        echo -e "${ERROR} 'metadata.json' - invariant_test_paths must be an array of strings"
        exit 1
    fi

    # 3) Existence check
    paths=$(jq -r '.invariant_test_paths[]?' "${repo_dir}/metadata.json")
    if [[ -n "$paths" ]]; then
        echo -e "${INFO} Checking paths listed in 'metadata.json'"
        while IFS= read -r p; do
            full="${repo_dir}/${p}"
            if [[ ! -e "$full" ]]; then
                print_header "$RED" "ERROR"
                echo -e "${ERROR} Path not found: ${p} (in 'metadata.json')"
                exit 1
            fi
        done <<< "$paths"
        echo -e "${SUCCESS} All invariant_test_paths in 'metadata.json' exist."
    else
        echo -e "${INFO} 'metadata.json' has an empty invariant_test_paths array, skipping existence check."
    fi

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


    print_header "$CYAN" "SKIP COMPATIBLE PATCH CHECK"
fi

# Clean untracked files in codebase before patch test
print_header "$CYAN" "CLEANING BEFORE PATCH"
cd "${repo_dir}/codebase"
git clean -fdx
git reset --hard "$vulnerable_commit"
cd -

    print_header "$CYAN" "APPLYING PATCH"
    patched_bounty_dir="${repo_dir}/bounties/$(basename "$bounty_dir")"

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
        print_header "$CYAN" "VALIDATING & VERIFYING INVARIANT TEST PATHS"

        # 1) Require the key
        if ! jq -e 'has("invariant_test_paths")' "${repo_dir}/metadata.json" >/dev/null; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} 'metadata.json' must contain an 'invariant_test_paths' key with an array of strings (e.g., \"invariant_test_paths\": [])"
            exit 1
        fi

        # 2) Validate type & contents
        if ! jq -e '
            (.invariant_test_paths | type == "array") and
            all(.invariant_test_paths[]; type == "string")
        ' "${repo_dir}/metadata.json" >/dev/null; then
            print_header "$RED" "ERROR"
            echo -e "${ERROR} 'metadata.json' - invariant_test_paths must be an array of strings"
            exit 1
        fi

        # 3) Existence check
        paths=$(jq -r '.invariant_test_paths[]?' "${repo_dir}/metadata.json")
        if [[ -n "$paths" ]]; then
            echo -e "${INFO} Checking paths listed in 'metadata.json'"
            while IFS= read -r p; do
                full="${repo_dir}/${p}"
                if [[ ! -e "$full" ]]; then
                    print_header "$RED" "ERROR"
                    echo -e "${ERROR} Path not found: ${p} (in 'metadata.json')"
                    exit 1
                fi
            done <<< "$paths"
            echo -e "${SUCCESS} All invariant_test_paths in 'metadata.json' exist."
        else
            echo -e "${INFO} 'metadata.json' has an empty invariant_test_paths array, skipping existence check."
        fi

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

    print_header "$GREEN" "PATCH MODE SUCCEEDED"
    echo -e "${SUCCESS} Patch completed successfully."
fi

