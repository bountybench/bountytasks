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

# Check if a base directory was provided
if [[ $# -lt 1 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} Usage: ./batch_ci_local.sh <base-directory> [--patch] [--check-invariants]"
    echo -e "${ERROR} Example: ./batch_ci_local.sh ./astropy --patch --check-invariants"
    exit 1
fi

# Create logs directory
mkdir -p "local_ci_logs"

base_dir="$1"
shift

# Process optional flags
patch_flag=""
invariants_flag=""
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --patch) patch_flag="--patch" ;;
        --check-invariants) invariants_flag="--check-invariants" ;;
        *) echo -e "${ERROR} Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Create summary arrays
successful_bounties=()
failed_bounties=()
skipped_bounties=()

# Find all bounty directories - only match the direct bounty_X directories, not subdirectories
print_header "$CYAN" "FINDING ALL BOUNTY DIRECTORIES"
bounty_dirs=($(find "$base_dir" -type d -path "*/bounties/bounty_*" -not -path "*/bounties/bounty_*/*/bounty_*" | grep -E "/bounties/bounty_[0-9]+$" | sort))

if [[ ${#bounty_dirs[@]} -eq 0 ]]; then
    print_header "$RED" "ERROR"
    echo -e "${ERROR} No bounty directories found in $base_dir"
    exit 1
fi

echo -e "${INFO} Found ${#bounty_dirs[@]} bounty directories"
for dir in "${bounty_dirs[@]}"; do
    echo -e "${INFO} - $dir"
done
echo

# Run each bounty
total=${#bounty_dirs[@]}
current=1

for bounty_dir in "${bounty_dirs[@]}"; do
    print_header "$CYAN" "RUNNING BOUNTY $current/$total: $bounty_dir"
    echo -e "${INFO} Command: ./run_ci_local.sh $bounty_dir $patch_flag $invariants_flag"
    
    # Run the command and capture output
    output=$(./run_ci_local.sh "$bounty_dir" $patch_flag $invariants_flag 2>&1)
    exit_status=$?
    
    # Check if failure is just due to missing invariant files
    if [[ $exit_status -ne 0 && "$invariants_flag" == "--check-invariants" && 
          ("$output" =~ "invariant_scores.json: [Errno 2] No such file or directory" ||
           "$output" =~ "Missing invariant_thresholds key in repo metadata.json" ||
           "$output" =~ "No invariant_scores key found in bounty scores" ||
           "$output" =~ "No invariant_scores key found in repo scores") &&
          ! ("$output" =~ "Invariant violations:") ]]; then
        print_header "$YELLOW" "BOUNTY $bounty_dir SKIPPED INVARIANTS"
        skipped_bounties+=("$bounty_dir")
        echo "$output"
        
        # Create logs directory if it doesn't exist
        mkdir -p "local_ci_logs"
        
        # Extract the project name from the path (e.g., "astropy" from "./astropy/bounties/bounty_0")
        project_name=$(echo "$bounty_dir" | sed -E 's|^\./([^/]+)/.*|\1|')
        bounty_name=$(basename "$bounty_dir")
        
        # Construct log filename
        log_flags=""
        [[ -n "$patch_flag" ]] && log_flags="${log_flags}_patch"
        [[ -n "$invariants_flag" ]] && log_flags="${log_flags}_invariants"
        log_flags=${log_flags#_}
        
        log_file="local_ci_logs/${project_name}_${bounty_name}_skipped"
        [[ -n "$log_flags" ]] && log_file="${log_file}_${log_flags}"
        log_file="${log_file}.txt"
        
        echo "$output" > "$log_file"
        echo -e "${INFO} Log saved to $log_file"
    elif [[ $exit_status -eq 0 ]]; then
        print_header "$GREEN" "BOUNTY $bounty_dir PASSED"
        successful_bounties+=("$bounty_dir")
        # Just print the output for successful bounties
        echo "$output"
    else
        print_header "$RED" "BOUNTY $bounty_dir FAILED"
        failed_bounties+=("$bounty_dir")
        
        # Create logs directory if it doesn't exist
        mkdir -p "local_ci_logs"
        
        # Extract the project name from the path (e.g., "astropy" from "./astropy/bounties/bounty_0")
        project_name=$(echo "$bounty_dir" | sed -E 's|^\./([^/]+)/.*|\1|')
        bounty_name=$(basename "$bounty_dir")
        
        # Construct log filename with project, bounty, and flags info
        log_flags=""
        [[ -n "$patch_flag" ]] && log_flags="${log_flags}_patch"
        [[ -n "$invariants_flag" ]] && log_flags="${log_flags}_invariants"
        # Remove leading underscore if present
        log_flags=${log_flags#_}
        
        # Create the log filename
        log_file="local_ci_logs/${project_name}_${bounty_name}_failed"
        [[ -n "$log_flags" ]] && log_file="${log_file}_${log_flags}"
        log_file="${log_file}.txt"
        
        echo "$output" > "$log_file"
        echo -e "${INFO} Log saved to $log_file"
        
        # Also print the output
        echo "$output"
    fi
    
    current=$((current + 1))
    echo
done

# Print summary
print_header "$CYAN" "SUMMARY"
echo -e "${INFO} Total bounties: $total"
echo -e "${SUCCESS} Successful bounties: ${#successful_bounties[@]}"
echo -e "${ERROR} Failed bounties: ${#failed_bounties[@]}"
echo -e "${WARNING} Skipped bounties (missing invariants): ${#skipped_bounties[@]}"
echo

if [[ ${#successful_bounties[@]} -gt 0 ]]; then
    print_header "$GREEN" "SUCCESSFUL BOUNTIES"
    for bounty in "${successful_bounties[@]}"; do
        echo -e "${SUCCESS} - $bounty"
    done
    echo
fi

if [[ ${#skipped_bounties[@]} -gt 0 ]]; then
    print_header "$YELLOW" "SKIPPED BOUNTIES (MISSING INVARIANTS)"
    for bounty in "${skipped_bounties[@]}"; do
        # Extract project and bounty name for the log reference
        project_name=$(echo "$bounty" | sed -E 's|^\./([^/]+)/.*|\1|')
        bounty_name=$(basename "$bounty")
        
        # Construct log flags string
        log_flags=""
        [[ -n "$patch_flag" ]] && log_flags="${log_flags}_patch"
        [[ -n "$invariants_flag" ]] && log_flags="${log_flags}_invariants"
        log_flags=${log_flags#_}
        
        # Construct log filename
        log_file="local_ci_logs/${project_name}_${bounty_name}_skipped"
        [[ -n "$log_flags" ]] && log_file="${log_file}_${log_flags}"
        log_file="${log_file}.txt"
        
        echo -e "${WARNING} - $bounty (log: $log_file)"
    done
    echo
fi

if [[ ${#failed_bounties[@]} -gt 0 ]]; then
    print_header "$RED" "FAILED BOUNTIES"
    for bounty in "${failed_bounties[@]}"; do
        # Extract project and bounty name for the log reference
        project_name=$(echo "$bounty" | sed -E 's|^\./([^/]+)/.*|\1|')
        bounty_name=$(basename "$bounty")
        
        # Construct log flags string
        log_flags=""
        [[ -n "$patch_flag" ]] && log_flags="${log_flags}_patch"
        [[ -n "$invariants_flag" ]] && log_flags="${log_flags}_invariants"
        log_flags=${log_flags#_}
        
        # Construct log filename
        log_file="local_ci_logs/${project_name}_${bounty_name}_failed"
        [[ -n "$log_flags" ]] && log_file="${log_file}_${log_flags}"
        log_file="${log_file}.txt"
        
        echo -e "${ERROR} - $bounty (log: $log_file)"
    done
    echo
fi

# Exit with error if any bounty failed (but not if they were just skipped due to missing invariants)
if [[ ${#failed_bounties[@]} -gt 0 ]]; then
    exit 1
fi

exit 0