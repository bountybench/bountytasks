#!/bin/bash

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


apply_patches() {
    local repo_dir="$1"
    local bounty_dir="$2"
    shift 2  # Skip first two args, remaining are patch mappings

    if [[ $# -eq 0 ]]; then
        log_info "No patches provided, skipping patch application."
        exit 1
    fi

    print_header "$CYAN" "APPLYING PATCHES"
    patched_bounty_dir="${bounty_dir}/patch_files"
    log_info "Applying patches to $repo_dir"

    while [[ $# -gt 1 ]]; do
        local source_file="$1"
        local target_file="$2"
        shift 2 # Move to next pair

        source_full_path="$patched_bounty_dir/$source_file"
        target_full_path="$repo_dir/$target_file"

        if [[ ! -f "$source_full_path" ]]; then
            log_error "Patch file missing: $source_full_path"
            continue
        fi

        target_dir=$(dirname "$target_full_path")
        if [[ ! -d "$target_dir" ]]; then
            log_info "Creating directory $target_dir"
            mkdir -p "$target_dir"
        fi

        log_info "Copying $source_full_path to $target_full_path"
        cp "$source_full_path" "$target_full_path"
    done
}

# Function to cancel all currently queued workflows
cancel_queued_and_running_workflows() {
    local repo_owner="cy-suite"
    local repo_name="$repo_dir"

    log_info "Fetching all queued and running workflows..."

    all_workflows=$(gh run list --repo "$repo_owner/$repo_name" --status queued --json databaseId -q '.[].databaseId')
    all_workflows+=" "$(gh run list --repo "$repo_owner/$repo_name" --status in_progress --json databaseId -q '.[].databaseId')

    if [[ -z "$all_workflows" || "$all_workflows" == " " ]]; then
        log_info "No queued or running workflows found."
        return 0
    fi

    log_info "Attempting to cancel the following workflows: $all_workflows"

    for run_id in $all_workflows; do
        for attempt in {1..3}; do
            response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                "https://api.github.com/repos/$repo_owner/$repo_name/actions/runs/$run_id/cancel")

            if [[ "$response" == "202" ]]; then
                log_success "Successfully canceled workflow run: $run_id"
                break
            else
                log_warning "Attempt $attempt: Failed to cancel workflow run: $run_id (HTTP $response)"
                sleep 5
            fi
        done
    done
}

add_workflow_dispatch() {
    local workflow_file_path=$1

    log_info "Adding workflow_dispatch trigger to $workflow_file_path"

    # Append workflow_dispatch to `on:` section
    awk '
    BEGIN {added=0}
    /^on:/ {
        print; 
        if (!added) { 
            print "  workflow_dispatch:"; 
            added=1; 
        }
        next
    }
    {print}
    ' "$workflow_file_path" > temp.yml && mv temp.yml "$workflow_file_path"

    #Ensure concurrency section exists and modify it
    awk -v workflow_name="${GITHUB_WORKFLOW:-default_workflow}" '
    BEGIN {concurrency_found=0}
    /^concurrency:/ {concurrency_found=1}
    /cancel-in-progress:/ {
        print "  cancel-in-progress: false"; # Force it to false
        next
    }
    /group:/ {
        print "  group: " workflow_name "-main"; # Ensure workflow-based grouping
        next
    }
    {print}
    END {
        if (concurrency_found == 0) {
            print "concurrency:\n  group: " workflow_name "-main\n  cancel-in-progress: false";
        }
    }' "$workflow_file_path" > temp.yml && mv temp.yml "$workflow_file_path"

    # Ensure we are on a real branch
    if [[ $(git symbolic-ref -q HEAD) == "" ]]; then
        log_warning "Detached HEAD detected. Checking out main..."
        echo "unit_test_results.txt" >> .gitignore
        # Ensure there's something to stash before stashing
        if [[ -n $(git status --porcelain) ]]; then
            log_info "Stashing uncommitted changes before switching branches..."
            git stash push -m "Temporary stash for switching branches"
        else
            log_info "No changes to stash."
        fi
        
        # Switch to main branch safely
        git checkout main || git checkout -b main origin/main

        # Only attempt to pop the stash if a stash exists
        if [[ $(git stash list | wc -l) -gt 0 ]]; then
            log_info "Restoring stashed changes..."
            git stash pop
        else
            log_warning "No stashed changes to apply."
        fi
    fi
    git add --all
    git commit -m "Temporarily add workflow_dispatch trigger for CI" || {
        log_error "Failed to commit workflow changes."
        exit 1
    }
    git push || {
        log_error "Failed to push changes to remote."
        exit 1
    }

    git clean -fdx # remove all changes that are uncommitted
}

# Get the current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
log_info "Current branch: $current_branch"

repo_dir="$1"
codebase_dir="codebase"
github_dir=".github"
workflow_file="$2"
bounty_dir="$3"
shift 3 # Remove first two arguments, remaining ones are patches
patch_list=("$@")

cd "$codebase_dir" || { log_error "Failed to change directory to $codebase_dir"; exit 1; }
log_info "Now in the codebase directory: $(pwd)"

# Apply patches before committing workflow changes
apply_patches "$repo_dir" "${patch_list[@]}"

if [[ ! -d "$github_dir" ]]; then
    log_warning "No .github folder found in codebase."
    exit 1
fi

cd "$github_dir" || { log_error "Failed to change directory to $github_dir"; exit 1; }
workflows_dir="workflows"

if [[ ! -d "$workflows_dir" ]]; then
    log_error "Workflows directory does not exist: $workflows_dir"
    exit 1
fi

cd "$workflows_dir" || { log_error "Failed to change directory to $workflows_dir"; exit 1; }
print_header "$CYAN" "RUNNING CI/CD PIPELINE"
log_info "Running CI/CD pipeline from .github/workflows"

if [[ ! -f "$workflow_file" ]]; then
    log_error "No workflow file found in .github/workflows"
    log_info "Files in .github/workflows: $(ls -a)"
    exit 1
fi
add_workflow_dispatch "$workflow_file"

if ! command -v gh &>/dev/null; then
    log_info "Installing GitHub CLI (gh)"
    apt-get update && apt-get install -y gh || { log_error "Failed to install GitHub CLI."; exit 1; }
fi

if ! gh auth status &>/dev/null; then
    log_info "Logging into GitHub CLI"
    gh auth login || {
        log_error "Failed to authenticate with GitHub CLI. Attempting GitHub API trigger."
        GITHUB_TOKEN=$(gh auth token)
        owner="cy-suite"
        repo=$(basename -s .git $(git config --get remote.origin.url))
        response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/$owner/$repo/actions/workflows/$workflow_file/dispatches" \
            -d "{\"ref\":\"$current_branch\"}")
        if [[ "$response" == "204" ]]; then
            log_success "CI/CD pipeline triggered successfully via GitHub API."
            exit 0
        else
            log_error "Failed to trigger CI/CD pipeline via GitHub API. HTTP status: $response"
            exit 1
        fi
    }
fi

# Cancel any queued workflows before triggering a new one
cancel_queued_and_running_workflows

status=1
gh workflow run "CI" -R "cy-suite/$repo_dir"

if [[ $? -eq 0 ]]; then
    log_success "CI/CD pipeline triggered successfully."
    gh run list -R "cy-suite/$repo_dir" --json databaseId,status,conclusion --limit 1
    status=0
else
    log_error "Failed to run CI/CD pipeline."
fi

# Wait a few seconds to ensure CI/CD starts
sleep 30

# Cleanup: Remove the commit that added workflow_dispatch
log_info "Cleaning up temporary commit..."
git reset --hard HEAD~1
git push --force

last_commit_message=$(git log -1 --pretty=%B)
if [[ "$last_commit_message" == "Temporarily add workflow_dispatch trigger for CI" ]]; then
    log_warning "Temporary commit is still there!"
else
    log_success "Temporary commit removed!"
fi

if [[ $status -eq 0 ]]; then
    exit 0
else
    exit 1
fi
