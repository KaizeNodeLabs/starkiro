# Starknet Devsuite Quick Installation 🚀

Welcome to **Starkiro CLI**, your one-stop solution to quickly set up your Dojo Engine development environment! This script installs `asdf` and the required Dojo plugins, so you can hit the ground running on your Starknet game development journey.

## Quick Start

Run the following command to install `asdf` and all the essential tools:

### Latest
```bash
curl -s https://raw.githubusercontent.com/KaizeNodeLabs/starkiro/main/cli/install_dojo_dev_suit.sh | bash
```

### Specific versions
```bash
curl -s https://raw.githubusercontent.com/KaizeNodeLabs/starkiro/main/cli/install_dojo_dev_suit.sh -o install_dojo_dev_suit.sh
bash install_dojo_dev_suit.sh --scarb <version> --dojo <version>
```

## What This Script Does 🛠️

1. Installs **asdf**, a powerful version manager.
2. Installs the latest versions of:
   - `scarb`
   - `dojo`
3. Sets global defaults for `scarb` and `dojo`.
4. Configures your shell session for immediate use.

## Prerequisites ✅

Ensure you have the following installed before running the script:
- **Git**
- **Curl**
- **Bash** or **Zsh** shell

## Detailed Steps

If you want to understand each step of the installation process, here’s what the script does:

1. Checks your operating system (supports macOS and Linux).
2. Installs `asdf` if it’s not already installed.
3. Adds `asdf` initialization to your shell configuration file (`.bashrc` or `.zshrc`).
4. Installs and configures the following tools:
   - `scarb`: The Cairo package manager.
   - `dojo`: The framework for on-chain games on Starknet.
5. Sets global versions for `asdf` plugins.
6. Restarts your shell session to apply the changes.

## Troubleshooting 🛠️

If you encounter any issues:
- Ensure your shell configuration files (`.bashrc` or `.zshrc`) are correctly sourced.
- Verify you have `git` and `curl` installed by running:
  ```bash
  git --version
  curl --version
  ```
- Open an issue in this repository if you run into errors.

## Contributing 🤝

We’re always looking for ways to improve the installation process! Feel free to:
- Fork the repository
- Create a branch
- Submit a pull request

Let’s make Dojo Engine development accessible for everyone!

## License 📜

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

