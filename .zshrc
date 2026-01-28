#!/usr/bin/env zsh
# ZSH run commands

# Idempotent path helper - only adds if not already present
path_append() { [[ ":$PATH:" != *":$1:"* ]] && PATH="$PATH:$1"; }
path_prepend() { [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }

# SSH agent - reuse existing or start new
SSH_ENV="$HOME/.ssh-agent.env"
if [ -f "$SSH_ENV" ]; then
    source "$SSH_ENV" > /dev/null
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        eval "$(ssh-agent -s)" > /dev/null
        echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$SSH_ENV"
        echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$SSH_ENV"
    fi
else
    eval "$(ssh-agent -s)" > /dev/null
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$SSH_ENV"
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$SSH_ENV"
fi

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
	path_prepend /opt/homebrew/bin
fi

# allow programs installed via pip to be put on the path
path_append "$(python3 -c 'import site; print(site.USER_BASE)')/bin"

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

# NVM loaded in .myrc

 # Added by Docker Desktop
[ -s "/Users/westwater/.docker/init-zsh.sh" ] && source /Users/westwater/.docker/init-zsh.sh || true

[ -s "$HOME/.sde/profile/profile.sh" ] && source $HOME/.sde/profile/profile.sh

# >>> coursier install directory >>>
path_append "/Users/westwater/Library/Application Support/Coursier/bin"

# Created by `pipx` on 2025-03-10 22:45:28
path_append "/Users/westwater/.local/bin"

# fzf
# moved from myrc as it wasn't loading for some reason
# ctrl + t: search files in cwd using fzf
export FZF_CTRL_T_COMMAND="fd -t d -d 1 ."
# Replaces reverse searching menu with fzf
# to get .fzf.zsh file, run $(brew --prefix)/opt/fzf/install
[ -f "$HOME/.fzf.zsh" ] && source ~/.fzf.zsh
export GOROOT="$(brew --prefix go)/libexec"

# Claude - dynamic config based on current directory
claude() {
    if [ -d ".g/.claude" ]; then
        local config_dir="$(pwd)/.g/.claude"
        local mcp_args=()
        if [ -f "$config_dir/mcp.json" ]; then
            mcp_args=(--mcp-config "$config_dir/mcp.json")
            echo "[claude] Found MCP config: $config_dir/mcp.json"
        fi
        CLAUDE_CONFIG_DIR="$config_dir" command claude "${mcp_args[@]}" "$@"
    else
        command claude "$@"
    fi
}
alias note='~/.g/note'
