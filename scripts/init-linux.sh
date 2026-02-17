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
# delta (git pager with syntax highlighting)
if ! command -v delta &>/dev/null; then
    echo "> installing delta"
    DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    curl -L -o /tmp/delta.deb "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_$(dpkg --print-architecture).deb"
    sudo dpkg -i /tmp/delta.deb
    rm /tmp/delta.deb
fi
apt_install direnv
apt_install eza
apt_install bat
# bat is installed as batcat on Debian/Ubuntu due to naming conflict
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    sudo ln -sf $(which batcat) /usr/local/bin/bat
fi
apt_install fzf
apt_install gnupg
apt_install xclip  # for clipboard aliases

# uv (Python version/package manager)
if ! command -v uv &>/dev/null; then
    echo "> installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# rbenv
if [ ! -d "$HOME/.rbenv" ]; then
    echo "> installing rbenv"
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Nerd fonts for powerlevel10k (MesloLGS NF)
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
    echo "> installing MesloLGS NF fonts"
    mkdir -p "$FONT_DIR"
    curl -L -o "$FONT_DIR/MesloLGS NF Regular.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    curl -L -o "$FONT_DIR/MesloLGS NF Bold.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    curl -L -o "$FONT_DIR/MesloLGS NF Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    curl -L -o "$FONT_DIR/MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
    fc-cache -f -v
fi

# Common setup (uv Python, sdkman, coursier, .zshrc cleanup)
source "$(dirname "$0")/init-common.sh"

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s $(which zsh)
fi

echo ""
echo "Linux post-install notes:"
echo "- Log out and back in for zsh to take effect"
