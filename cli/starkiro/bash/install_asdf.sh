#!/bin/bash

set -e  # Exit on error
set -o pipefail

# Check for OS
OS=$(uname -s)
if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
  echo "Unsupported OS: $OS"
  exit 1
fi

install_asdf() {
  if ! command -v asdf &>/dev/null; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
    echo -e '\n. $HOME/.asdf/asdf.sh' >>~/.bashrc
    echo -e '\n. $HOME/.asdf/completions/asdf.bash' >>~/.bashrc
    if [[ "$OS" == "Darwin" ]]; then
      echo -e '\n. $HOME/.asdf/asdf.sh' >>~/.zshrc
      echo -e '\n. $HOME/.asdf/completions/asdf.bash' >>~/.zshrc
    fi
    source ~/.bashrc || source ~/.zshrc
  fi
}


main() {
  install_asdf
}

main
