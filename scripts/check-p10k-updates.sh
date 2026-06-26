#!/bin/zsh
# Check for p10k updates in background, notify if outdated (once per day).
# Called from .myrc on shell startup.
#
# Deferred to the first prompt via a precmd hook so nothing prints during
# zsh init. Printing mid-init (the old behaviour) trips Powerlevel10k's
# instant-prompt "console output during zsh initialization" warning.

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-update-check"
CHECK_INTERVAL=86400  # 24 hours in seconds

_p10k_update_check() {
    # Run once: drop the hook on the first prompt
    add-zsh-hook -d precmd _p10k_update_check

    # Skip if not a git repo
    [[ -d "$P10K_DIR/.git" ]] || return

    # Skip if checked recently (both fetch AND notification)
    if [[ -f "$CACHE_FILE" ]]; then
        local last_check=$(cat "$CACHE_FILE" 2>/dev/null)
        local now=$(date +%s)
        if (( now - ${last_check:-0} < CHECK_INTERVAL )); then
            return
        fi
    fi

    # Fetch in the background. By now the prompt is drawn and init is done,
    # so any output lands after the prompt instead of during instant-prompt.
    (
        cd "$P10K_DIR" || exit
        git fetch origin master --quiet 2>/dev/null
        local behind=$(git rev-list HEAD..origin/master --count 2>/dev/null)

        # Cache the timestamp
        date +%s > "$CACHE_FILE"

        if (( behind > 0 )); then
            print -P "%F{yellow}p10k: $behind commits behind. Run 'p10k-update' to update.%f"
        fi
    ) &!
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _p10k_update_check
