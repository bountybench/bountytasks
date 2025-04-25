execute_if_exists() {
    local script_path="$1"
    if [ -f "$script_path" ]; then
        echo "Executing $script_path"
        bash "$script_path"
    else
        echo "$script_path not found, skipping."
    fi
    }

    get_modified_dirs() {
    git diff --diff-filter=ACMDR --name-only origin/main...HEAD | while read -r file; do
        ##################################
        # First part
        ##################################
        # If the file path includes "bounties/bounty_{digits}", extract and echo it.
        if [[ "$file" =~ (.*bounties/bounty_[0-9]+) ]]; then
        dir="${BASH_REMATCH[1]}"
        if [[ -d "$dir" ]]; then
            echo "$dir"
        fi
        fi

        ##################################
        # Second part
        ##################################
        # Skip if it already matches "bounties/bounty_{digits}" or contains metadata.json
        if [[ "$file" =~ .*/bounties/bounty_[0-9]+ ]] || [[ "$file" =~ metadata.json ]]; then
        continue
        else
        # Get the base directory
        baseDir="$(dirname "$file")"
        # Check if baseDir contains "bounties" somewhere
        if [[ -d "$baseDir/bounties" ]]; then
            rootOfBounties="$baseDir/bounties"
            # For each bounty subfolder under rootOfBounties, echo if non-essentials check passes
            for subDir in "$rootOfBounties"/bounty_[0-9]*; do
            if [[ -d "$subDir" && "$subDir" =~ /bounty_[0-9]+$ ]]; then
                echo "$subDir"
            fi
            done
        fi
        fi
    done | sort -u
}

checkout_vulnerable_commit() {
    local dir="$1"
    if [[ -f "$dir/bounty_metadata.json" ]]; then
        vulnerable_commit=$(jq -r '.["vulnerable_commit"]' "$dir/bounty_metadata.json")
        
        if [[ -n "$vulnerable_commit" ]]; then
        echo "Found vulnerable commit: $vulnerable_commit in $dir"

        git submodule update --init "$task_dir"
        echo "Cleaning repository to remove all changes and untracked files..."
        checkout_main "$dir"

        task_dir=$(dirname "$(dirname "$dir")")
        cd "$task_dir/codebase" || exit 1

        # Update the submodule and checkout the vulnerable commit
        git checkout "$vulnerable_commit"

        cd - || exit 1
        else
        echo "No vulnerable commit found in $dir/bounty_metadata.json"
        exit 1
        fi
    else
        echo "No bounty_metadata.json file found in $dir"
        exit 1
    fi
}

checkout_main() {
    local dir="$1"
    task_dir=$(dirname "$(dirname "$dir")")
    echo "Checking out main branch at $task_dir/codebase"
    cd "$task_dir/codebase" || exit 1
    echo "Cleaning up the codebase"
    git reset --hard HEAD
    sudo git clean -fdx

    echo "Checking if 'main' branch exists"
    if git rev-parse --verify main >/dev/null 2>&1; then
        echo "'main' branch exists"
    else
        echo "'main' branch does NOT exist."
        if git rev-parse --verify master >/dev/null 2>&1; then
        echo "'master' branch exists - renaming 'master' to 'main'"
        git branch -m master main
        elif git rev-parse --verify develop >/dev/null 2>&1; then
        echo "'develop' branch exists - renaming 'develop' to 'main'"
        git branch -m develop main
        else
        echo "Neither 'main' nor 'master' branch exists. Exiting."
        exit 1
        fi
    fi

    # Checkout 'main' branch
    echo "Checking out 'main' branch at $task_dir/codebase"
    git checkout main --force
    cd - || exit 1
}

check_server_ready() {
    # Timeout per container in seconds
    TIMEOUT=${TIMEOUT:-180}
    # Interval between checks in seconds
    INTERVAL=${INTERVAL:-1}

    # Get all running containers
    containers=$(docker ps --format '{{.Names}}')

    for container in $containers; do
        echo "Checking readiness for $container..."

        # Check if container has a health check
        has_health=$(docker inspect --format '{{if .Config.Healthcheck}}true{{else}}false{{end}}' "$container")
        if [ "$has_health" = "true" ]; then
        echo "Container has a health check. Waiting to become healthy..."
        elapsed=0
        success=0
        while [ $elapsed -lt $TIMEOUT ]; do
            status=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null)
            if [ "$status" == "healthy" ]; then
            success=1
            break
            fi
            sleep "$INTERVAL"
            elapsed=$((elapsed + INTERVAL))
        done
        if [ $success -eq 1 ]; then
            echo "$container is healthy."
            continue
        else
            echo "Timeout: $container did not become healthy within $TIMEOUT seconds." >&2
            exit 1
        fi
        else
        # Get exposed TCP ports
        ports=$(docker inspect --format '{{range $p, $conf := .NetworkSettings.Ports}}{{range $conf}}{{.HostPort}} {{end}}{{end}}' "$container")
        if [ -z "$ports" ]; then
            echo "No exposed ports for $container. Skipping readiness check." >&2
            continue
        fi

        elapsed=0
        all_success=0
        while [ $elapsed -lt $TIMEOUT ]; do
            success=1
            for port_spec in $ports; do
            port=$(echo "$port_spec" | cut -d'/' -f1)
            proto=$(echo "$port_spec" | cut -d'/' -f2)
            if [ "$proto" != "tcp" ]; then
                continue  # Skip non-TCP ports
            fi

            # Perform TCP check
            if ! nc -z -w 1 localhost "$port" &>/dev/null; then
                success=0
                break
            fi
            done

            if [ $success -eq 1 ]; then
            all_success=1
            break
            fi

            sleep "$INTERVAL"
            elapsed=$((elapsed + INTERVAL))
        done

        if [ $all_success -eq 1 ]; then
            echo "$container is ready via port check on all ports."
        else
            echo "Timeout: $container not ready after $TIMEOUT seconds." >&2
            exit 1
        fi
        fi
    done

    echo "All containers are ready!"
}