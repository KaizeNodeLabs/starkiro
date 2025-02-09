#!/bin/bash

GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Root directory of the repository
REPO_ROOT="$(git rev-parse --show-toplevel)"
error_file=$(mktemp)

echo -e "${GREEN}Repository root directory: $REPO_ROOT${NC}"

# function to list modified directories
list_modified_dirs() {
  git diff --diff-filter=AM --name-only HEAD^ HEAD -- starknet/contracts | \
    awk -F'/' '{print $1 "/" $2 "/" $3}' | sort -u
}

# function to list all directories
list_all_dirs() {
  find starknet/contracts -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

# Function to process directory
process_directory() {
  local directory="$1"
  echo -e "${GREEN}Testing directory: $directory${NC}"
  
  local dir_path="${REPO_ROOT}/${directory}"
  if ! cd "$dir_path"; then
    echo -e "${RED}Failed to change to directory: $dir_path${NC}"
    echo "1" >> "$error_file"
    return
  }

  echo -e "${GREEN}Running scarb build and snforge test in: $directory${NC}"
  if ! { scarb build && snforge test; } >error.log 2>&1; then
    echo -e "${RED}Tests failed in directory: $directory${NC}"
    cat error.log
    echo "1" >> "$error_file"
  else
    echo -e "${GREEN}Tests succeeded in directory: $directory${NC}"
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
  echo -e "${GREEN}Force flag detected, testing all directories...${NC}"
  modified_dirs=$(list_all_dirs)
else
  echo -e "${GREEN}Testing modified directories only...${NC}"
  modified_dirs=$(list_modified_dirs)
fi

# Process each directory
for directory in $modified_dirs; do
  process_directory "$directory"
done

# Check for errors
if grep -q "1" "$error_file"; then
  echo -e "\n${RED}Some tests have failed, please check the output above.${NC}"
  rm "$error_file"
  exit 1
else
  if [ -z "$modified_dirs" ]; then
    echo -e "\n${GREEN}No new changes detected${NC}"
  else
    echo -e "\n${GREEN}All tests completed successfully${NC}"
  fi
  rm "$error_file"
  exit 0
fi
