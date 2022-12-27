#!/usr/bin/env bash

set -eo pipefail

# Prerequisites

# macs come pre-installed with git so cline this repo
# git clone https://github.com/westwater dotfiles ~/dotfiles

# Install xcode
# xcode-select --install

# Install Rosetta
# softwareupdate --install-rosetta

# Install Kitty terminal on Apple silicon Mac
# ./kitty.sh

# you can now run this script

# ========================================================================================

# Install brew (there is an m1 version but you need to specify arch before brew everytime)
if command -v brew &> /dev/null
then
	echo "brew already installed"
else
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	# Then add the following to zshrc
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/westwater/.zshrc
	eval "$(/opt/homebrew/bin/brew shellenv)"
	# source zshrc
	source ~/.zshrc
fi

brew_install() {
    if brew list $1 &>/dev/null; then
        echo "${1} is already installed"
    else
        brew install $1
    fi
}

# Install micro to start editing files easily
brew_install micro

# Add ssh key to github account
# ssh-keygen -t ed25519 -C "gmwestwater@hotmail.co.uk"

# Make sure ssh-agent is up
# eval "$(ssh-agent -s)"

# Make sure ssh-config file exists
[ -f $HOME/.ssh/config ] || { echo "> Creating ssh config"; touch $HOME/.ssh/config; }

# Add config to ~/.ssh/config
# Host *
#  AddKeysToAgent yes
#  UseKeychain yes
#  IdentityFile ~/.ssh/id_ed25519

# add
# ssh-add -K ~/.ssh/id_ed25519

# Install terminal commands
brew_install diff-so-fancy
brew_install rbenv
brew_install direnv
brew_install exa
brew_install bat
# docker might not intall because of the extension commands
brew_install docker
# command -v sdk fails for some reason in the script and it will always try to install
command -v sdk > /dev/null || { echo "> installing sdkman"; curl -s "https://get.sdkman.io" | bash; }
brew_install pyenv
# run the following after install to get reverse search linked to fzf
# $(brew --prefix)/opt/fzf/install
brew_install fzf

# Upgrading bash
# brew install bash
# sudo micro /etc/shells
# add /opt/homebrew/bin/bash
# make sure to use the following shebang #!/usr/bin/env bash (uses first bash on PATH)

# Install oh-my-zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install terminal theme
[ -d $HOME/.oh-my-zsh/custom/themes/powerlevel10k ] || { echo "> installing powerlevel10k"; git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k; }

# Install oh-my-zsh plugins
[ -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] || { echo "> installing zsh-autosuggestions"; git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions; }
[ -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] || { echo "> installing zsh-syntax-highlighting"; git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; }
# Clone vault


[ -d $HOME/vault ] || { echo "> Cloning vault"; git clone git@github.com:westwater/vault.git $HOME/vault; }

# Install nerd fonts

# brew tap homebrew/cask-fonts
# brew install --cask font-hack-nerd-font 
# font-meslo-lg

 # clone g
 # [ -d $HOME/.g ] || { echo "> Installing g"; git clone git@github.com:westwater/g.git $HOME/.g;} 

# link dotfiles to host directories
# ./link.sh
