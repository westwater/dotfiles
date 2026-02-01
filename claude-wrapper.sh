#!/bin/bash
# Claude wrapper - loads global settings and MCP configs based on current directory
#
# MCP config loading order:
#   1. Global: ~/.g/global/mcp.json (always loaded if exists)
#   2. Local: .g/.claude/mcp.json or .claude/mcp.json (if exists)

GLOBAL_SETTINGS="$HOME/.g/global/settings.json"
GLOBAL_MCP="$HOME/.g/global/mcp.json"

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
    echo "[claude] Found global mcp.json at $GLOBAL_MCP"
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
