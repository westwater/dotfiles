#!/bin/zsh
# Check for p10k updates in background, notify if outdated
# Called from .myrc on shell startup

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-update-check"
CHECK_INTERVAL=86400  # 24 hours in seconds

check_updates() {
    # Skip if not a git repo
    [[ -d "$P10K_DIR/.git" ]] || return

    # Skip if checked recently
    if [[ -f "$CACHE_FILE" ]]; then
        local last_check=$(cat "$CACHE_FILE" 2>/dev/null)
        local now=$(date +%s)
        if (( now - last_check < CHECK_INTERVAL )); then
            # Check if we already found updates
            if [[ -f "${CACHE_FILE}.behind" ]]; then
                local behind=$(cat "${CACHE_FILE}.behind")
                if (( behind > 0 )); then
                    echo "\033[33mp10k: $behind commits behind. Run 'p10k-update' to update.\033[0m"
                fi
            fi
            return
        fi
    fi

    # Fetch in background and check
    (
        cd "$P10K_DIR" || exit
        git fetch origin master --quiet 2>/dev/null
        local behind=$(git rev-list HEAD..origin/master --count 2>/dev/null)

        # Cache the result
        date +%s > "$CACHE_FILE"
        echo "$behind" > "${CACHE_FILE}.behind"

        if (( behind > 0 )); then
            echo "\033[33mp10k: $behind commits behind. Run 'p10k-update' to update.\033[0m"
        fi
    ) &!
}

check_updates
