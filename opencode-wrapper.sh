#!/bin/bash
# opencode wrapper (`o`) — runs opencode against a repo's per-project .opencode
# config instead of the global one. Mirrors claude-wrapper.sh.
#
# Why this exists: the GLOBAL opencode config (~/.config/opencode/opencode.jsonc)
# is the SiriusXM LiteLLM setup used by the `oc` alias. `o` must never use that
# for side projects. Instead it injects a per-repo config via env vars:
#   OPENCODE_CONFIG      -> <store>/.opencode/opencode.jsonc  (provider/model)
#   OPENCODE_CONFIG_DIR  -> <store>/.opencode                 (agents/commands/...)
# Per-repo config (e.g. the lab gpt-oss provider) overrides the global one for
# that session only; the global file and the `oc` flow are untouched.
#
# Config dir resolution mirrors `g`/claude-wrapper: the central store reached via
# the project's `.g` symlink (.g/.opencode), else a local .opencode/.

config_dir=""
if [ -d ".g/.opencode" ]; then
    config_dir="$(pwd)/.g/.opencode"
elif [ -d ".opencode" ]; then
    config_dir="$(pwd)/.opencode"
fi

config_file=""
if [ -n "$config_dir" ]; then
    if [ -f "$config_dir/opencode.jsonc" ]; then
        config_file="$config_dir/opencode.jsonc"
    elif [ -f "$config_dir/opencode.json" ]; then
        config_file="$config_dir/opencode.json"
    fi
fi

# No per-repo config -> opencode would fall back to the GLOBAL (SiriusXM) config.
# Guard against accidentally running side-project work against the work proxy.
if [ -z "$config_file" ]; then
    echo "[o] This project has no .opencode config — opencode would use the global (SiriusXM) config."
    echo "[o] Run anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
    exec opencode "$@"
fi

echo "[o] Using per-repo config: $config_file"
OPENCODE_CONFIG="$config_file" OPENCODE_CONFIG_DIR="$config_dir" exec opencode "$@"
