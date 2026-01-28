#!/usr/bin/env bash

# macOS-specific setup
# Called by init.sh on Darwin systems

set -eo pipefail

echo "Setting up macOS..."

# Prerequisites (manual):
# - Install xcode: xcode-select --install
# - Install Rosetta (Apple Silicon): softwareupdate --install-rosetta
# - Install Kitty terminal: ./kitty.sh
# - Install nerd font: https://github.com/ryanoasis/nerd-fonts

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
brew_install exa
brew_install bat
brew_install docker
brew_install pyenv
brew_install fzf
brew_install gnupg

# sdkman
command -v sdk > /dev/null || { echo "> installing sdkman"; curl -s "https://get.sdkman.io" | bash; }

echo ""
echo "macOS post-install notes:"
echo "- Run \$(brew --prefix)/opt/fzf/install for fzf keybindings"
echo "- Add SSH key: ssh-keygen -t ed25519 -C 'your@email.com'"
echo "- GPG signing: gpg --full-generate-key"
