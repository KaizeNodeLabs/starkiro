#!/bin/bash

set -e  # Exit on error
set -o pipefail

# Check for OS
OS=$(uname -s)
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS"
  exit 1
fi


# Default versions
PLUGIN=""
VERSION=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --plugin)
      PLUGIN="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    *)
  esac
done

install_plugin() {
  asdf install "$PLUGIN" "$VERSION"
  asdf global  "$PLUGIN" "$VERSION"
}

main() {
  install_plugin
}

main
