#!/bin/bash

set -e  # Exit on error
set -o pipefail

# Check for OS
OS=$(uname -s)
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS"
  exit 1
fi

# Install asdf
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
    # Reload shell configuration
    source ~/.bashrc || source ~/.zshrc
    echo "asdf installed successfully!"
  else
    echo "asdf is already installed."
  fi
}

# Install asdf plugins and tools
install_asdf_tools() {
  echo "Installing asdf plugins and tools..."
  # Add plugins if they don't exist
  asdf plugin-add scarb https://github.com/software-mansion/asdf-scarb.git || true
  asdf plugin-add starknet-foundry https://github.com/kkallday/asdf-starknet-foundry.git || true

  # Install the latest versions of scarb and starknet-foundry
  asdf install scarb latest
  asdf install starknet-foundry latest

  # Set them as global
  asdf global scarb latest
  asdf global starknet-foundry latest
}

# Restart shell session
restart_shell_session() {
  echo "Restarting shell session..."
  exec $SHELL
}


# Main function
main() {
  install_asdf
  install_asdf_tools
  restart_shell_session
}

main
