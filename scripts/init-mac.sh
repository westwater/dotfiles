#!/usr/bin/env bash

# macOS-specific setup
# Called by init.sh on Darwin systems

set -eo pipefail

echo "Setting up macOS..."

# Prerequisites (manual):
# - Install xcode: xcode-select --install
# - Install Rosetta (Apple Silicon): softwareupdate --install-rosetta
# - Install Kitty terminal: ./kitty.sh

# Install brew
if command -v brew &> /dev/null; then
    echo "brew already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    source ~/.zshrc
fi

brew_install() {
    if brew list $1 &>/dev/null; then
        echo "${1} is already installed"
    else
        brew install $1
    fi
}

# Install tools via brew
brew_install micro
brew_install diff-so-fancy
brew_install rbenv
brew_install direnv
brew_install eza
brew_install bat
brew_install docker
brew_install pyenv
brew_install fzf
brew_install gnupg

# Nerd fonts for powerlevel10k
brew install --cask font-meslo-lg-nerd-font 2>/dev/null || echo "font-meslo-lg-nerd-font already installed"

# sdkman
command -v sdk > /dev/null || { echo "> installing sdkman"; curl -s "https://get.sdkman.io" | bash; }

# Clean up .zshrc - sdkman/nvm installers append duplicate init code (already in .myrc)
if [ -f "$HOME/.zshrc" ]; then
    sed -i '' '/^#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN/d' "$HOME/.zshrc"
    sed -i '' '/^export SDKMAN_DIR=/d' "$HOME/.zshrc"
    sed -i '' '/sdkman-init.sh/d' "$HOME/.zshrc"
    sed -i '' '/^export NVM_DIR=/d' "$HOME/.zshrc"
    sed -i '' '/NVM_DIR\/nvm.sh/d' "$HOME/.zshrc"
    sed -i '' '/NVM_DIR\/bash_completion/d' "$HOME/.zshrc"
fi

echo ""
echo "macOS post-install notes:"
echo "- Run \$(brew --prefix)/opt/fzf/install for fzf keybindings"
