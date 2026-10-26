#!/bin/bash
# Claude wrapper - loads global settings and MCP configs based on current directory
#
# MCP config loading order:
#   1. Global: ~/.g/global/mcp.json (always loaded if exists)
#   2. Local: .g/.claude/mcp.json or .claude/mcp.json (if exists)

GLOBAL_SETTINGS="$HOME/.g/global/settings.json"
GLOBAL_MCP="$HOME/.g/global/mcp.json"

# Load vault-managed env (e.g. CLAUDE_CODE_OAUTH_TOKEN) ONLY for headless/SSH
# sessions. In an interactive terminal the env token would override — and never
# refresh — the macOS Keychain OAuth login, forcing a re-login every session.
# Interactive Mac sessions deliberately fall through to the Keychain, which persists.
if [ ! -t 0 ] || [ -n "$SSH_CONNECTION" ]; then
    CLAUDE_VAULT_ENV="$HOME/vault/claude/.env"
    if [ -f "$CLAUDE_VAULT_ENV" ]; then
        set -a
        . "$CLAUDE_VAULT_ENV"
        set +a
    fi
fi

# Warn if not in ~/.g and no .g/ directory
if [ "$(pwd)" != "$HOME/.g" ] && [ ! -d ".g" ]; then
    echo "[claude] Warning: running claude with no .g/ - are you sure? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

settings_args=(--settings "$GLOBAL_SETTINGS")
config_dir=""

# Determine config directory
if [ -d ".g/.claude" ]; then
    config_dir="$(pwd)/.g/.claude"
elif [ -d ".claude" ]; then
    config_dir="$(pwd)/.claude"
fi

# Build mcp args - global first, then local
mcp_args=()
if [ -f "$GLOBAL_MCP" ]; then
    mcp_args=(--mcp-config "$GLOBAL_MCP")
else
    echo "[claude] No global mcp.json at $GLOBAL_MCP"
fi
if [ -n "$config_dir" ] && [ -f "$config_dir/mcp.json" ]; then
    echo "[claude] Found local mcp.json at $config_dir/mcp.json"
    mcp_args+=(--mcp-config "$config_dir/mcp.json")
fi

# Hold a sleep assertion for the whole session. Claude Code takes its own
# `caffeinate -i -t 300`, but that's a rolling 5-minute window it only renews
# while actively working - so an idle wait (a long background task, or waiting
# on the user) lets it lapse and the Mac idle-sleeps mid-session.
#   -i  no idle system sleep   -m  no disk idle sleep   -s  no sleep on AC
# Deliberately NOT -d: the display should still be allowed to turn off.
keepawake=()
if command -v caffeinate >/dev/null 2>&1; then
    keepawake=(caffeinate -i -m -s)
fi

# Subcommands (`mcp`, `rc`/`remote-control`, `setup-token`, ...) reject the
# injected --settings/--mcp-config flags, and `--mcp-config <configs...>` is
# VARIADIC so it silently swallows the subcommand as another config path -
# that is why `c rc` died with "MCP config file not found: .../rc". Pass
# subcommands straight through with no injected flags.
# `remote-control|rc` is hidden from --help but is a real subcommand.
case "$1" in
    agents|attach|auth|auto-mode|doctor|gateway|import|install|logs|mcp|\
    plugin|plugins|project|remote-control|rc|respawn|rm|setup-token|stop|kill|\
    ultrareview|update|upgrade)
        if [ -n "$config_dir" ]; then
            CLAUDE_CONFIG_DIR="$config_dir" exec command claude "$@"
        else
            exec command claude "$@"
        fi
        ;;
esac

# Flag order matters for a session: end with --settings (single-valued) rather
# than the variadic --mcp-config, so a stray positional stays a prompt.
if [ -n "$config_dir" ]; then
    CLAUDE_CONFIG_DIR="$config_dir" "${keepawake[@]}" command claude "${mcp_args[@]}" "${settings_args[@]}" "$@"
else
    "${keepawake[@]}" command claude "${mcp_args[@]}" "${settings_args[@]}" "$@"
fi
