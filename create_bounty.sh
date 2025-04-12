#!/bin/bash
# This script can quickly sets up the required file structure when adding a new bounty.

set -e

# 1. Check if we are in the bountybench root directory.
#    Adjust this check as necessary for your environment.
if [[ "$(basename "$PWD")" != "bountybench" ]]; then
  echo "Error: Please run this script from the 'bountybench' root directory."
  exit 1
fi

# 2. Read the repo folder name from user input.
if [ -z "$1" ]; then
  echo "Usage: $0 <repo_name>"
  exit 1
fi

REPO_NAME="$1"

# 3. Check if the repo folder exists; if not, create it.
if [ ! -d "$REPO_NAME" ]; then
  echo "Creating repo folder '$REPO_NAME'..."
  mkdir -p "$REPO_NAME"
fi

# 4. Check if there is a 'codebase' folder (this folder is the submodule).
#    If it doesn't exist, prompt for the submodule link and add it.
CODEBASE_DIR="$REPO_NAME/codebase"
if [ ! -d "$CODEBASE_DIR" ]; then
  echo "It looks like there is no 'codebase' submodule folder for '$REPO_NAME'."
  read -p "Enter the link for the codebase submodule (or press enter to skip): " SUBMODULE_LINK
  if [ -n "$SUBMODULE_LINK" ]; then
    echo "Adding submodule to 'codebase' folder..."
    git submodule add "$SUBMODULE_LINK" "$CODEBASE_DIR"
  else
    echo "No submodule link provided. Skipping submodule creation."
  fi
fi

# 5. Check for metadata.json; if missing, create a new one.
METADATA_FILE="$REPO_NAME/metadata.json"
if [ ! -f "$METADATA_FILE" ]; then
  echo "Creating new metadata.json..."
  cat <<EOF > "$METADATA_FILE"
{
    "target_host": ""
}
EOF
fi

# 6. Check for setup_repo_env.sh; if missing, create it.
SETUP_REPO_ENV="$REPO_NAME/setup_repo_env.sh"
if [ ! -f "$SETUP_REPO_ENV" ]; then
  echo "Creating setup_repo_env.sh..."
  cat <<'EOF' > "$SETUP_REPO_ENV"
#!/bin/bash
EOF
  chmod +x "$SETUP_REPO_ENV"
fi

# 7. Check or create the 'bounties' folder.
BOUNTIES_DIR="$REPO_NAME/bounties"
if [ ! -d "$BOUNTIES_DIR" ]; then
  echo "Creating bounties folder..."
  mkdir -p "$BOUNTIES_DIR"
fi

# 8. Determine the next bounty folder name.
#    We look for existing bounty_[x] folders and find the max.
NEXT_BOUNTY_NUM=0
if ls "$BOUNTIES_DIR" | grep -q "bounty_"; then
  MAX_BOUNTY=$(ls "$BOUNTIES_DIR" | grep "bounty_" | sed 's/bounty_//' | sort -n | tail -1)
  NEXT_BOUNTY_NUM=$((MAX_BOUNTY + 1))
fi
NEW_BOUNTY_FOLDER="bounty_${NEXT_BOUNTY_NUM}"

echo "Creating new bounty folder: $NEW_BOUNTY_FOLDER"
mkdir -p "$BOUNTIES_DIR/$NEW_BOUNTY_FOLDER"

# 9. Create the required files and directories in the new bounty folder.
#    9a. bounty_metadata.json
BOUNTY_METADATA_FILE="$BOUNTIES_DIR/$NEW_BOUNTY_FOLDER/bounty_metadata.json"
if [ ! -f "$BOUNTY_METADATA_FILE" ]; then
  echo "Creating bounty_metadata.json in $NEW_BOUNTY_FOLDER..."
  cat <<EOF > "$BOUNTY_METADATA_FILE"
{
  "bounty_link": "",
  "CWE": "",
  "CVE": "",
  "severity": "",
  "disclosure_bounty": "",
  "patch_bounty": "",
  "detect_prompt_some_info": "",
  "detect_prompt_less_info": "",
  "exploit_prompt": "",
  "patch": {
    "": ""
  },
  "vulnerable_commit": ""
}
EOF
fi

#    9b. exploit_files (with exploit.sh)
EXPLOIT_DIR="$BOUNTIES_DIR/$NEW_BOUNTY_FOLDER/exploit_files"
mkdir -p "$EXPLOIT_DIR"
EXPLOIT_SCRIPT="$EXPLOIT_DIR/exploit.sh"
if [ ! -f "$EXPLOIT_SCRIPT" ]; then
  echo "Creating exploit_files/exploit.sh..."
  cat <<'EOF' > "$EXPLOIT_SCRIPT"
#!/bin/bash
EOF
  chmod +x "$EXPLOIT_SCRIPT"
fi

#    9c. patch_files folder (can be empty)
PATCH_DIR="$BOUNTIES_DIR/$NEW_BOUNTY_FOLDER/patch_files"
mkdir -p "$PATCH_DIR"

#    9d. setup_files with setup_bounty_env.sh
SETUP_BOUNTY_DIR="$BOUNTIES_DIR/$NEW_BOUNTY_FOLDER/setup_files"
mkdir -p "$SETUP_BOUNTY_DIR"
SETUP_BOUNTY_SCRIPT="$SETUP_BOUNTY_DIR/setup_bounty_env.sh"
if [ ! -f "$SETUP_BOUNTY_SCRIPT" ]; then
  echo "Creating setup_files/setup_bounty_env.sh..."
  cat <<'EOF' > "$SETUP_BOUNTY_SCRIPT"
#!/bin/bash
EOF
  chmod +x "$SETUP_BOUNTY_SCRIPT"
fi

#    9e. verify_files with verify.sh
VERIFY_DIR="$BOUNTIES_DIR/$NEW_BOUNTY_FOLDER/verify_files"
mkdir -p "$VERIFY_DIR"
VERIFY_SCRIPT="$VERIFY_DIR/verify.sh"
if [ ! -f "$VERIFY_SCRIPT" ]; then
  echo "Creating verify_files/verify.sh..."
  cat <<'EOF' > "$VERIFY_SCRIPT"
#!/bin/bash
EOF
  chmod +x "$VERIFY_SCRIPT"
fi

echo "Done! The repo '$REPO_NAME' has been prepared, and bounty $NEXT_BOUNTY_NUM has been created."
