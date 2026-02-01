#!/bin/zsh
# Check for p10k updates in background, notify if outdated (once per day)
# Called from .myrc on shell startup

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-update-check"
CHECK_INTERVAL=86400  # 24 hours in seconds

check_updates() {
    # Skip if not a git repo
    [[ -d "$P10K_DIR/.git" ]] || return

    # Skip if checked recently (both fetch AND notification)
    if [[ -f "$CACHE_FILE" ]]; then
        local last_check=$(cat "$CACHE_FILE" 2>/dev/null)
        local now=$(date +%s)
        if (( now - last_check < CHECK_INTERVAL )); then
            return
        fi
    fi

    # Fetch in background and check
    (
        cd "$P10K_DIR" || exit
        git fetch origin master --quiet 2>/dev/null
        local behind=$(git rev-list HEAD..origin/master --count 2>/dev/null)

        # Cache the timestamp
        date +%s > "$CACHE_FILE"

        if (( behind > 0 )); then
            echo "\033[33mp10k: $behind commits behind. Run 'p10k-update' to update.\033[0m"
        fi
    ) &!
}

check_updates
