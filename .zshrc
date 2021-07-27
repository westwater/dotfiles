# ZSH
# Path to oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE="true"
# Display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Brew
eval "$(/opt/homebrew/bin/brew shellenv)"

export GPG_TTY=$(tty)

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

zstyle ':bracketed-paste-magic' active-widgets '.self-*' # instant pasting - see: https://github.com/zsh-users/zsh-syntax-highlighting/issues/295

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

eval "$(direnv hook zsh)"

function zsh_options() {
    PLUGIN_PATH="$HOME/.oh-my-zsh/plugins/"
    for plugin in $plugins; do
        echo "\n\nPlugin: $plugin"; grep -r "^function \w*" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/()//'| tr '\n' ', '; grep -r "^alias" $PLUGIN_PATH$plugin | awk '{print $2}' | sed 's/=.*//' |  tr '\n' ', '
    done
}

# custom zsh keybinds
bindkey -s '^G' ' | grep'

# re-source aliases to overwrite PL10K aliases
[[ -s "$HOME/dotfiles/.aliases" ]] && source "$HOME/dotfiles/.aliases"

# gcp
# updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
# enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
