#!/usr/bin/env bash
# prltc-hook-version: 3
# PRLTC auto-rewrite hook for Claude Code PreToolUse:Bash
# Transparently rewrites raw commands to their PRLTC equivalents.
# Uses `prltc rewrite` as single source of truth — no duplicate mapping logic here.
#
# To add support for new commands, update src/discover/registry.rs (PATTERNS + RULES).
#
# Exit code protocol for `prltc rewrite`:
#   0 + stdout  Rewrite found, no deny/ask rule matched → auto-allow
#   1           No PRLTC equivalent → pass through unchanged
#   2           Deny rule matched → pass through (Claude Code native deny handles it)
#   3 + stdout  Ask rule matched → rewrite but let Claude Code prompt the user

# --- Audit logging (opt-in via PRLTC_HOOK_AUDIT=1) ---
_prltc_audit_log() {
  if [ "${PRLTC_HOOK_AUDIT:-0}" != "1" ]; then return; fi
  local action="$1" original="$2" rewritten="${3:--}"
  local dir="${PRLTC_AUDIT_DIR:-${HOME}/.local/share/prltc}"
  mkdir -p "$dir"
  printf '%s | %s | %s | %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$action" "$original" "$rewritten" \
    >> "${dir}/hook-audit.log"
}

# Guards: skip silently if dependencies missing
if ! command -v prltc &>/dev/null || ! command -v jq &>/dev/null; then
  _prltc_audit_log "skip:no_deps" "-"
  exit 0
fi

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  _prltc_audit_log "skip:empty" "-"
  exit 0
fi

# Skip heredocs (prltc rewrite also skips them, but bail early)
case "$CMD" in
  *'<<'*) _prltc_audit_log "skip:heredoc" "$CMD"; exit 0 ;;
esac

# Rewrite via prltc — single source of truth for all command mappings and permission checks.
# Use "|| EXIT_CODE=$?" to capture non-zero exit codes without triggering set -e.
EXIT_CODE=0
REWRITTEN=$(prltc rewrite "$CMD" 2>/dev/null) || EXIT_CODE=$?

case $EXIT_CODE in
  0)
    # Rewrite found, no permission rules matched — safe to auto-allow.
    if [ "$CMD" = "$REWRITTEN" ]; then
      _prltc_audit_log "skip:already_prltc" "$CMD"
      exit 0
    fi
    ;;
  1)
    # No PRLTC equivalent — pass through unchanged.
    _prltc_audit_log "skip:no_match" "$CMD"
    exit 0
    ;;
  2)
    # Deny rule matched — let Claude Code's native deny rule handle it.
    _prltc_audit_log "skip:deny_rule" "$CMD"
    exit 0
    ;;
  3)
    # Ask rule matched — rewrite the command but do NOT auto-allow so that
    # Claude Code prompts the user for confirmation.
    ;;
  *)
    exit 0
    ;;
esac

_prltc_audit_log "rewrite" "$CMD" "$REWRITTEN"

# Build the updated tool_input with all original fields preserved, only command changed.
ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '.command = $cmd')

if [ "$EXIT_CODE" -eq 3 ]; then
  # Ask: rewrite the command, omit permissionDecision so Claude Code prompts.
  jq -n \
    --argjson updated "$UPDATED_INPUT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "updatedInput": $updated
      }
    }'
else
  # Allow: output the rewrite instruction in Claude Code hook format.
  jq -n \
    --argjson updated "$UPDATED_INPUT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": "PRLTC auto-rewrite",
        "updatedInput": $updated
      }
    }'
fi
