#!/usr/bin/env bash

# Symlinks dotfiles to the home directory
# Works on both macOS and Linux

OS="$(uname)"

# Common symlinks (both platforms)
ln -sf $PWD/.zshrc ~
ln -sf $PWD/.gitconfig ~

# Kitty terminal config
mkdir -p $HOME/.config/kitty
ln -sf $PWD/kitty.conf $HOME/.config/kitty/kitty.conf

# sbt config
mkdir -p $HOME/.sbt/1.0
ln -sf $PWD/global.sbt $HOME/.sbt/1.0/global.sbt

# symlink zsh plugins
if [ ! -d "$HOME/.oh-my-zsh/plugins" ]; then
    echo "Error: oh-my-zsh not installed. Run ./init.sh first, or install oh-my-zsh manually."
    exit 1
fi
ln -sf $PWD/zsh/prepend-sudo $HOME/.oh-my-zsh/plugins/prepend-sudo

# macOS-specific symlinks
if [[ "$OS" == "Darwin" ]]; then
    # nix-darwin config
    mkdir -p $HOME/.nixpkgs
    ln -sf $PWD/nix/darwin-configuration.nix $HOME/.nixpkgs/darwin-configuration.nix
fi

echo "Symlinks created for $OS"
