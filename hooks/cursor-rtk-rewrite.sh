#!/usr/bin/env bash
# prltc-hook-version: 1
# PRLTC Cursor Agent hook — rewrites shell commands to use prltc for token savings.
# Works with both Cursor editor and cursor-cli (they share ~/.cursor/hooks.json).
# Cursor preToolUse hook format: receives JSON on stdin, returns JSON on stdout.
# Requires: prltc >= 0.23.0, jq
#
# This is a thin delegating hook: all rewrite logic lives in `prltc rewrite`,
# which is the single source of truth (src/discover/registry.rs).
# To add or change rewrite rules, edit the Rust registry — not this file.

if ! command -v jq &>/dev/null; then
  echo "[prltc] WARNING: jq is not installed. Hook cannot rewrite commands. Install jq: https://jqlang.github.io/jq/download/" >&2
  exit 0
fi

if ! command -v prltc &>/dev/null; then
  echo "[prltc] WARNING: prltc is not installed or not in PATH. Hook cannot rewrite commands. Install: https://github.com/ekjotsinghmakhija/prltc#installation" >&2
  exit 0
fi

# Version guard: prltc rewrite was added in 0.23.0.
PRLTC_VERSION=$(prltc --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -n "$PRLTC_VERSION" ]; then
  MAJOR=$(echo "$PRLTC_VERSION" | cut -d. -f1)
  MINOR=$(echo "$PRLTC_VERSION" | cut -d. -f2)
  if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 23 ]; then
    echo "[prltc] WARNING: prltc $PRLTC_VERSION is too old (need >= 0.23.0). Upgrade: cargo install prltc" >&2
    exit 0
  fi
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  echo '{}'
  exit 0
fi

# Delegate all rewrite logic to the Rust binary.
# prltc rewrite exits 1 when there's no rewrite — hook passes through silently.
REWRITTEN=$(prltc rewrite "$CMD" 2>/dev/null) || { echo '{}'; exit 0; }

# No change — nothing to do.
if [ "$CMD" = "$REWRITTEN" ]; then
  echo '{}'
  exit 0
fi

jq -n --arg cmd "$REWRITTEN" '{
  "permission": "allow",
  "updated_input": { "command": $cmd }
}'
