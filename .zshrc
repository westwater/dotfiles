#!/usr/bin/env zsh
# ZSH run commands

# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE="true"
# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Brew
if type "brew" > /dev/null; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Bash (brew)
# Add before path to mac bash for /env bash shebang
if [ -d /opt/homebrew/bin ]; then
	export PATH=/opt/homebrew/bin:$PATH
fi

# allow programs installed via pip to be put on the path
export PATH="${PATH}:$(python3 -c 'import site; print(site.USER_BASE)')/bin"

# needed for git gpg commit signing
# if still having trouble try killing the gpg agent with
# killall gpg-agent
export GPG_TTY=$(tty)

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

 # instant pasting - see: https://github.com/zsh-users/zsh-syntax-highlighting/issues/295
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# removes percent symbol on terminal start
unsetopt PROMPT_SP

setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data

#zsh-autosuggestions settings
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC="true"

plugins=(zsh-autosuggestions zsh-syntax-highlighting prepend-sudo)

# load my run commands
[[ -s ~/dotfiles/.myrc ]] && source ~/dotfiles/.myrc

# source after .myrc to load theme
[[ -s $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

function zsh_options() {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}

# ZSH keybinds
# use showkey -a to identify keystrokes
# brew install showkey
# alternitavely press ctrl+v and then the key to see unicode

bindkey -s '^G' ' | grep'

# re-source aliases to overwrite PL10K aliases
[[ -s "$HOME/dotfiles/.aliases" ]] && source "$HOME/dotfiles/.aliases"

# gcp
# updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
# enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
