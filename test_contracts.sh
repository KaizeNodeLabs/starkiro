#!/bin/bash

GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Root directory of the repository
REPO_ROOT="$(git rev-parse --show-toplevel)"
error_file=$(mktemp)

echo -e "${GREEN}Repository root directory: $REPO_ROOT${NC}"

# Function to list modified directories
list_modified_dirs() {
  # Ensure previous commit exists before running git diff
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    git diff --diff-filter=AM --name-only HEAD^ HEAD -- examples/starknet/contracts | awk -F'/' '{print $1 "/" $2 "/" $3 "/" $4}' | sort -u
  else
    git ls-files -- examples/starknet/contracts | awk -F'/' '{print $1 "/" $2 "/" $3 "/" $4}' | sort -u
  fi
}

# Function to list all directories
list_all_dirs() {
  find examples/starknet/contracts -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
    echo "$dir"
  done
}

# Function to process directory
process_directory() {
  local directory="$1"
  echo -e "\n${GREEN}=== Testing directory: $directory ===${NC}"
  
  # Store the original directory to return to later
  local original_dir=$(pwd)
  
  local dir_path="${REPO_ROOT}/${directory}"
  
  # Check if directory exists
  if [ ! -d "$dir_path" ]; then
    echo -e "${RED}Directory does not exist: $dir_path${NC}"
    echo "1" >> "$error_file"
    return
  fi
  
  if ! cd "$dir_path"; then
    echo -e "${RED}Failed to change to directory: $dir_path${NC}"
    echo "1" >> "$error_file"
    return
  fi

  # Check if Scarb.toml exists
  if [ ! -f "Scarb.toml" ]; then
    echo -e "${RED}No Scarb.toml found in: $dir_path${NC}"
    echo "1" >> "$error_file"
    cd "$original_dir"
    return
  fi

  echo -e "${GREEN}Running scarb build...${NC}"
  if ! scarb build; then
    echo -e "${RED}Build failed in directory: $directory${NC}"
    echo "1" >> "$error_file"
    cd "$original_dir"
    return
  fi

  echo -e "${GREEN}Running snforge test...${NC}"
  if ! snforge test; then
    echo -e "${RED}Tests failed in directory: $directory${NC}"
    echo "1" >> "$error_file"
  else
    echo -e "${GREEN}✓ All tests passed in: $directory${NC}"
  fi
  
  # Return to original directory
  cd "$original_dir"
}

# Determine directories to test
force=false
if [ "$1" == "-f" ]; then
  force=true
fi

if [ "$force" = true ]; then
  echo -e "${GREEN}Force flag detected, testing all directories...${NC}"
  modified_dirs=$(list_all_dirs)
else
  echo -e "${GREEN}Checking for modified directories...${NC}"
  modified_dirs=$(list_modified_dirs)

  # Fallback to all directories if no changes detected
  if [ -z "$modified_dirs" ]; then
    echo -e "${GREEN}No modified files detected. Running tests on all directories...${NC}"
    modified_dirs=$(list_all_dirs)
  fi
fi

echo -e "${GREEN}Directories to test: $modified_dirs${NC}"

# Run tests for each directory
for directory in $modified_dirs; do
  process_directory "$directory"
done

# Check for errors
if grep -q "1" "$error_file"; then
  echo -e "\n${RED}Some tests have failed, please check the output above.${NC}"
  rm "$error_file"
  exit 1
else
  echo -e "\n${GREEN}All tests completed successfully${NC}"
  rm "$error_file"
  exit 0
fi
