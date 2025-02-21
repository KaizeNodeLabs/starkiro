#!/bin/bash

GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

git_setup() {
  upstream="git@github.com:KaizeNodeLabs/starkiro.git"
  if git remote | grep -q "^upstream$"; then
    upstream_url=$(git remote get-url upstream)
    if [ "$upstream_url" != "$upstream" ]; then
      git remote set-url upstream "$upstream"
      echo "'upstream' remote URL updated to KaizeNodeLabs/starkiro."
    fi
  else
      git remote add upstream "$upstream"
      echo "'upstream' remote added to KaizeNodeLabs/starkiro."
  fi
  git fetch upstream
}

# Root directory of the repository
REPO_ROOT="$(git rev-parse --show-toplevel)"
error_file=$(mktemp)

echo -e "${GREEN}Repository root directory: $REPO_ROOT${NC}"

# function to list modified directories
list_modified_dirs() {
  git diff --diff-filter=AM --name-only HEAD^ HEAD -- cairo starknet | \
    awk -F'/' '{print $1 "/" $2 "/" $3}' | sort -u
}

# function to list all directories
list_all_dirs() {
  find cairo starknet -mindepth 2 -maxdepth 2 -type d 2>/dev/null
}

# Function to process directory
process_directory() {
  echo "Processing directory '$1'"
  local directory="$1"
  local dir_path="${REPO_ROOT}/${directory}"

  echo -e "${GREEN}Changing to directory: $dir_path${NC}"
  if ! cd "$dir_path"; then
    echo -e "${RED}Failed to change to directory: $dir_path${NC}"
    echo "1" >> "$error_file"
    return
  fi

  echo -e "${GREEN}Running scarb build in directory: $directory${NC}"
  if ! scarb build >error.log 2>&1; then
    echo -e "${RED}scarb build failed in directory: $directory${NC}"
    cat error.log
    echo "1" >> "$error_file"
  else
    echo -e "${GREEN}scarb build succeeded in directory: $directory${NC}"
  fi

  rm -f error.log
}

# Is there the -f flag?
force=false
if [ "$1" == "-f" ]; then
  force=true
fi

# Get the list of directories to process
if [ "$force" = true ]; then
  echo -e "${GREEN}Force flag detected, processing all directories...${NC}"
  modified_dirs=$(list_all_dirs)
else
  echo -e "${GREEN}Detecting modified directories only...${NC}"
  modified_dirs=$(list_modified_dirs)
fi

# Process each directory
for directory in $modified_dirs; do
  process_directory "$directory"
done

# Check for errors
if grep -q "1" "$error_file"; then
  echo -e "\n${RED}Some directories have errors, please check the list above.${NC}"
  rm "$error_file"
  exit 1
else
  if [ -z "$modified_dirs" ]; then
    echo -e "\n${GREEN}No new changes detected${NC}"
  else
    echo -e "\n${GREEN}All builds were completed successfully${NC}"
  fi
  rm "$error_file"
  exit 0
fi
