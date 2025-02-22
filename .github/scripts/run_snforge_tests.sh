#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to run tests in a directory
run_tests() {
    local dir=$1
    echo -e "${BLUE}📝 Running tests in $dir${NC}"
    
    # Find all Scarb.toml files in the directory
    find "$dir" -name "Scarb.toml" -exec dirname {} \; | while read -r project_dir; do
        echo -e "${BLUE}🔍 Testing project in $project_dir${NC}"
        cd "$project_dir"
        
        # Run snforge tests
        if snforge test; then
            echo -e "${GREEN}✅ Tests passed for $project_dir${NC}"
        else
            echo -e "${RED}❌ Tests failed for $project_dir${NC}"
            exit 1
        fi
        
        # Return to original directory
        cd - > /dev/null
    done
}

# Main execution
echo -e "${BLUE}🚀 Starting test execution${NC}"

# Save the root directory
ROOT_DIR=$(pwd)

# Test contracts directory
if [ -d "$ROOT_DIR/examples/starknet/contracts" ]; then
    run_tests "$ROOT_DIR/examples/starknet/contracts"
else
    echo -e "${RED}⚠️ Contracts directory not found at $ROOT_DIR/examples/starknet/contracts${NC}"
fi

# Test scripts directory
if [ -d "$ROOT_DIR/examples/starknet/scripts" ]; then
    run_tests "$ROOT_DIR/examples/starknet/scripts"
else
    echo -e "${RED}⚠️ Scripts directory not found at $ROOT_DIR/examples/starknet/scripts${NC}"
fi

echo -e "${GREEN}✅ All tests completed successfully${NC}"