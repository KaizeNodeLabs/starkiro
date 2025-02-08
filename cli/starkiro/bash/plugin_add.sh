#!/bin/bash

set -e  # Exit on error
set -o pipefail

# Check for OS
OS=$(uname -s)
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS"
  exit 1
fi

PLUGIN=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --plugin)
      PLUGIN="$2"
      shift 2
      ;;
    *)
      ;;
  esac
done

add_plugin() {
  asdf plugin-add "$PLUGIN" || true
}

main() {
  add_plugin
}

main
