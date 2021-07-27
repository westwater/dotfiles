# Prerequisites

# Add ssh key to github account
# ssh-keygen -t ed25519 -C "gmwestwater@hotmail.co.uk"

# Make sure ssh-agent is up
# eval "$(ssh-agent -s)"

# Make sure ssh-config file exists
[ -f $HOME/.ssh/config ] || { echo "> Creating ssh config"; touch $HOME/.ssh/config; }

# Add config
# Host *
#  AddKeysToAgent yes
#  UseKeychain yes
#  IdentityFile ~/.ssh/id_ed25519

# add
# ssh-add -K ~/.ssh/id_ed25519


# Install brew
command -v brew > /dev/null || { echo "> installing brew"; brew install diff-so-fancy; /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; }

# Install terminal commands
command -v diff-so-fancy > /dev/null || { echo "> installing diff-so-fancy"; brew install diff-so-fancy; }
command -v rbenv > /dev/null || { echo "> installing rbenv"; brew install rbenv; }
command -v direnv > /dev/null || { echo "> installing direnv"; brew install direnv; }
command -v exa > /dev/null || { echo "> installing exa"; brew install exa; }
command -v bat > /dev/null || { echo "> installing bat"; brew install bat; }

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
