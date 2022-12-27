# ZSH
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

# pyenv
# remember to run pyenv rehash after upgrading to change version in shims
if type "pyenv" > /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$(pyenv root)/shims:$PATH"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
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

plugins=(zsh-autosuggestions zsh-syntax-highlighting)

# load my run commands
[[ -s ~/dotfiles/.myrc ]] && source ~/dotfiles/.myrc

# source after .myrc to load theme
source $ZSH/oh-my-zsh.sh

# hook direnv into shell
eval "$(direnv hook zsh)"

function zsh_options() {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}

# ZSH keybinds
# use showkey -a to identify keystrokes
# brew install showkey
# utility
bindkey -s '^G' ' | grep'

# kitty
bindkey "\e[1;3D"  backward-word # ⌥←
bindkey "\e[1;3C"  forward-word # ⌥→
bindkey  "\e[1;9D" beginning-of-line # ⌘→
bindkey  "\e[1;9C" end-of-line # ⌘←

# re-source aliases to overwrite PL10K aliases
[[ -s "$HOME/dotfiles/.aliases" ]] && source "$HOME/dotfiles/.aliases"

# gcp
# updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
# enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# Replaces reverse searching menu with fzf
# to get .fzf.zsh file, run $(brew --prefix)/opt/fzf/install
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# shell completions
[[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh)

