#!/usr/bin/env bash

# Linux-specific setup (Debian/Ubuntu)
# Called by init.sh on Linux systems

set -eo pipefail

echo "Setting up Linux (Debian/Ubuntu)..."

apt_install() {
    if dpkg -l $1 &>/dev/null; then
        echo "${1} is already installed"
    else
        sudo apt install -y $1
    fi
}

# Update package list
sudo apt update

# Install tools via apt
apt_install zsh
apt_install micro
apt_install git
apt_install curl
apt_install diff-so-fancy
apt_install direnv
apt_install exa
apt_install bat
apt_install fzf
apt_install gnupg
apt_install xclip  # for clipboard aliases

# pyenv dependencies and install
apt_install build-essential
apt_install libssl-dev
apt_install zlib1g-dev
apt_install libbz2-dev
apt_install libreadline-dev
apt_install libsqlite3-dev
apt_install libncursesw5-dev
apt_install xz-utils
apt_install tk-dev
apt_install libxml2-dev
apt_install libxmlsec1-dev
apt_install libffi-dev
apt_install liblzma-dev

if [ ! -d "$HOME/.pyenv" ]; then
    echo "> installing pyenv"
    curl https://pyenv.run | bash
fi

# rbenv
if [ ! -d "$HOME/.rbenv" ]; then
    echo "> installing rbenv"
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# sdkman
command -v sdk > /dev/null || { echo "> installing sdkman"; curl -s "https://get.sdkman.io" | bash; }

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s $(which zsh)
fi

echo ""
echo "Linux post-install notes:"
echo "- Log out and back in for zsh to take effect"
echo "- Install nerd fonts for powerlevel10k: https://github.com/ryanoasis/nerd-fonts"
echo "- Add SSH key: ssh-keygen -t ed25519 -C 'your@email.com'"
echo "- GPG signing: gpg --full-generate-key"
