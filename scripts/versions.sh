#!/usr/bin/env zsh
# Check installed tools for available updates via Homebrew
# Usage: versions

_VERSIONS_TOOLS=(
    micro
)

versions() {
    echo "Checking tool versions...\n"

    for tool in "${_VERSIONS_TOOLS[@]}"; do
        local outdated=$(brew outdated --verbose "$tool" 2>/dev/null)
        if [[ -n "$outdated" ]]; then
            printf "  %-12s %s\n" "$tool" "$outdated"
        else
            local installed=$(brew list --versions "$tool" 2>/dev/null)
            if [[ -n "$installed" ]]; then
                printf "  %-12s %s ✓\n" "$tool" "${installed#* }"
            else
                printf "  %-12s not installed\n" "$tool"
            fi
        fi
    done

    echo ""
}
