#!/usr/bin/env bash

# Symlinks dotfiles to the home directory
# Works on both macOS and Linux

OS="$(uname)"
VAULT_DIR="$HOME/vault"

# Common symlinks (both platforms)
ln -sf $PWD/.zshrc ~
ln -sf $PWD/.p10k.zsh ~

# Kitty terminal config
mkdir -p $HOME/.config/kitty
ln -sf $PWD/kitty.conf $HOME/.config/kitty/kitty.conf

# Neovim config
ln -sfn $PWD/nvim $HOME/.config/nvim

# Micro editor config
ln -sfn $PWD/micro $HOME/.config/micro

# sbt config
mkdir -p $HOME/.sbt/1.0
ln -sf $PWD/global.sbt $HOME/.sbt/1.0/global.sbt

# symlink zsh plugins
if [ ! -d "$HOME/.oh-my-zsh/plugins" ]; then
    echo "Error: oh-my-zsh not installed. Run ./init.sh first, or install oh-my-zsh manually."
    exit 1
fi
# macOS-specific symlinks
if [[ "$OS" == "Darwin" ]]; then
    # nix-darwin config
    mkdir -p $HOME/.nixpkgs
    ln -sf $PWD/nix/darwin-configuration.nix $HOME/.nixpkgs/darwin-configuration.nix
fi

# Vault-backed config dirs (require ~/vault to be present)
if [ -d "$VAULT_DIR" ]; then
    mkdir -p "$HOME/.config"

    # gh CLI — symlink whole dir (hosts.yml has tokens)
    if [ ! -e "$HOME/.config/gh" ]; then
        ln -s "$VAULT_DIR/config/gh" "$HOME/.config/gh"
        echo "Linked ~/.config/gh"
    fi

    # rclone — symlink conf file only (dir may have other state)
    if [ ! -e "$HOME/.config/rclone/rclone.conf" ]; then
        mkdir -p "$HOME/.config/rclone"
        ln -s "$VAULT_DIR/config/rclone/rclone.conf" "$HOME/.config/rclone/rclone.conf"
        echo "Linked ~/.config/rclone/rclone.conf"
    fi

    # exercism — symlink conf file only
    if [ ! -e "$HOME/.config/exercism/user.json" ]; then
        mkdir -p "$HOME/.config/exercism"
        ln -s "$VAULT_DIR/config/exercism/user.json" "$HOME/.config/exercism/user.json"
        echo "Linked ~/.config/exercism/user.json"
    fi
else
    echo "Warning: ~/vault not found, skipping vault-backed config symlinks"
fi

echo "Symlinks created for $OS"
