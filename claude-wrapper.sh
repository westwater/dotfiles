#!/bin/bash
# Claude wrapper - loads global settings and MCP configs based on current directory
#
# MCP config loading order:
#   1. Global: ~/.g/global/mcp.json (always loaded if exists)
#   2. Local: .g/.claude/mcp.json or .claude/mcp.json (if exists)

GLOBAL_SETTINGS="$HOME/.g/global/settings.json"
GLOBAL_MCP="$HOME/.g/global/mcp.json"

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

if [ -n "$config_dir" ]; then
    CLAUDE_CONFIG_DIR="$config_dir" command claude "${settings_args[@]}" "${mcp_args[@]}" "$@"
else
    command claude "${settings_args[@]}" "${mcp_args[@]}" "$@"
fi
