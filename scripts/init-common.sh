#!/usr/bin/env bash

# Shared setup logic sourced by init-mac.sh and init-linux.sh

# OS-aware sed in-place (macOS needs '' arg, Linux doesn't)
if [[ "$(uname)" == "Darwin" ]]; then
    sed_inplace() { sed -i '' "$@"; }
else
    sed_inplace() { sed -i "$@"; }
fi

# uv Python versions and symlinks
if command -v uv &>/dev/null; then
    if ! uv python list --only-installed 2>/dev/null | grep -q "cpython-3.12"; then
        echo "> installing Python via uv"
        uv python install 3.11 3.12
    fi
    if [ ! -L "$HOME/.local/bin/python" ]; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$HOME/.local/bin/python3.12" "$HOME/.local/bin/python3"
        ln -sf "$HOME/.local/bin/python3.12" "$HOME/.local/bin/python"
    fi
fi

# sdkman
command -v sdk > /dev/null || { echo "> installing sdkman"; curl -s "https://get.sdkman.io" | bash; }

# coursier + metals (via sdkman)
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install coursier 2>/dev/null || true
cs install metals 2>/dev/null || true

# Clean up .zshrc - sdkman/nvm installers append duplicate init code (already in .myrc)
if [ -f "$HOME/.zshrc" ]; then
    sed_inplace '/^#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN/d' "$HOME/.zshrc"
    sed_inplace '/^export SDKMAN_DIR=/d' "$HOME/.zshrc"
    sed_inplace '/sdkman-init.sh/d' "$HOME/.zshrc"
    sed_inplace '/^export NVM_DIR=/d' "$HOME/.zshrc"
    sed_inplace '/NVM_DIR\/nvm.sh/d' "$HOME/.zshrc"
    sed_inplace '/NVM_DIR\/bash_completion/d' "$HOME/.zshrc"
fi
