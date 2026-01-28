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
# diff-so-fancy (not in apt, install from GitHub)
if [ ! -d "$HOME/.diff-so-fancy" ]; then
    echo "> installing diff-so-fancy"
    git clone https://github.com/so-fancy/diff-so-fancy.git ~/.diff-so-fancy
    sudo ln -sf ~/.diff-so-fancy/diff-so-fancy /usr/local/bin/diff-so-fancy
fi
apt_install direnv
apt_install eza
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

# sdkman
command -v sdk > /dev/null || { echo "> installing sdkman"; curl -s "https://get.sdkman.io" | bash; }

# Clean up .zshrc - sdkman/nvm installers append duplicate init code (already in .myrc)
if [ -f "$HOME/.zshrc" ]; then
    sed -i '/^#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN/d' "$HOME/.zshrc"
    sed -i '/^export SDKMAN_DIR=/d' "$HOME/.zshrc"
    sed -i '/sdkman-init.sh/d' "$HOME/.zshrc"
    sed -i '/^export NVM_DIR=/d' "$HOME/.zshrc"
    sed -i '/NVM_DIR\/nvm.sh/d' "$HOME/.zshrc"
    sed -i '/NVM_DIR\/bash_completion/d' "$HOME/.zshrc"
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s $(which zsh)
fi

echo ""
echo "Linux post-install notes:"
echo "- Log out and back in for zsh to take effect"
