#!/bin/bash

set -e  # Exit on error
set -o pipefail

# Check for OS
OS=$(uname -s)
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS"
  exit 1
fi

# Usage function
usage() {
  echo "Usage: $0 [--scarb <version>] [--snfoundry <version>]"
  echo "  --scarb: Specify the version of scarb to install (default: latest)"
  echo "  --snfoundry: Specify the version of starknet-foundry to install (default: latest)"
  exit 1
}

# Default versions
SCARB_VERSION="latest"
SNFOUNDRY_VERSION="latest"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --scarb)
      SCARB_VERSION="$2"
      shift 2
      ;;
    --snfoundry)
      SNFOUNDRY_VERSION="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

# Install dependencies
install_asdf() {
  if ! command -v asdf &>/dev/null; then
    echo "Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
    echo -e '\n. $HOME/.asdf/asdf.sh' >>~/.bashrc
    echo -e '\n. $HOME/.asdf/completions/asdf.bash' >>~/.bashrc
    if [[ "$OS" == "Darwin" ]]; then
      echo -e '\n. $HOME/.asdf/asdf.sh' >>~/.zshrc
      echo -e '\n. $HOME/.asdf/completions/asdf.bash' >>~/.zshrc
    fi
    source ~/.bashrc || source ~/.zshrc
    echo "asdf installed successfully!"
  else
    echo "asdf is already installed."
  fi
}

install_plugins_and_tools() {
  # Add asdf plugins
  asdf plugin-add scarb || true
  asdf plugin-add starknet-foundry || true

  # Install specified versions
  echo "Installing scarb version: $SCARB_VERSION"
  asdf install scarb "$SCARB_VERSION"
  asdf global scarb "$SCARB_VERSION"

  echo "Installing starknet-foundry version: $SNFOUNDRY_VERSION"
  asdf install starknet-foundry "$SNFOUNDRY_VERSION"
  asdf global starknet-foundry "$SNFOUNDRY_VERSION"
}

main() {
  install_asdf
  install_plugins_and_tools

  echo "All tools have been installed successfully!"
}

main
