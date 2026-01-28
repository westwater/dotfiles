#!/usr/bin/env bash

set -eo pipefail

# Detect OS
OS="$(uname)"
echo "Detected OS: $OS"

# ========================================================================================
# Common setup (works on both macOS and Linux)
# ========================================================================================

# Check if zsh is installed, offer to install if not
if ! command -v zsh &>/dev/null; then
    read -p "Zsh is not installed. Would you like to install it? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Zsh is required. Exiting."
        exit 1
    fi
    echo "Installing zsh..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install zsh
    elif [[ "$OS" == "Linux" ]]; then
        sudo apt update && sudo apt install -y zsh
    fi
fi

# Install oh-my-zsh (this will overwrite your zshrc)
[ -d $HOME/.oh-my-zsh ] || sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
rm -f ~/.zshrc

# symlink all files
./link.sh

# Install terminal theme
[ -d $HOME/.oh-my-zsh/custom/themes/powerlevel10k ] || { echo "> installing powerlevel10k"; git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k; }

# Install oh-my-zsh plugins
[ -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] || { echo "> installing zsh-autosuggestions"; git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions; }
[ -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] || { echo "> installing zsh-syntax-highlighting"; git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; }

# ========================================================================================
# OS-specific setup
# ========================================================================================

if [[ "$OS" == "Darwin" ]]; then
    ./scripts/init-mac.sh
elif [[ "$OS" == "Linux" ]]; then
    ./scripts/init-linux.sh
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# ========================================================================================
# Common post-install
# ========================================================================================

# Clone vault (if you have access)
[ -d $HOME/vault ] || { echo "> Cloning vault"; git clone git@github.com:westwater/vault.git $HOME/vault || echo "Vault clone failed - you may need to set up SSH keys first"; }

echo ""
echo "Setup complete! Run 'source ~/.zshrc' or open a new terminal."
