#!/bin/bash
# PRLTC auto-rewrite hook for Claude Code PreToolUse:Bash
# Transparently rewrites raw commands to their prltc equivalents.
# Outputs JSON with updatedInput to modify the command before execution.

# Guards: skip silently if dependencies missing
if ! command -v prltc &>/dev/null || ! command -v jq &>/dev/null; then
  exit 0
fi

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

# Extract the first meaningful command (before pipes, &&, etc.)
# We only rewrite if the FIRST command in a chain matches.
FIRST_CMD="$CMD"

# Skip if already using prltc
case "$FIRST_CMD" in
  prltc\ *|*/prltc\ *) exit 0 ;;
esac

# Skip commands with heredocs, variable assignments as the whole command, etc.
case "$FIRST_CMD" in
  *'<<'*) exit 0 ;;
esac

REWRITTEN=""

# --- Git commands ---
if echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+status([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git status/prltc git status/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+diff([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git diff/prltc git diff/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+log([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git log/prltc git log/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+add([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git add/prltc git add/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+commit([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git commit/prltc git commit/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+push([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git push/prltc git push/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+pull([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git pull/prltc git pull/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+branch([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git branch/prltc git branch/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+fetch([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git fetch/prltc git fetch/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+stash([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git stash/prltc git stash/')
elif echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+show([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git show/prltc git show/')

# --- GitHub CLI ---
elif echo "$FIRST_CMD" | grep -qE '^gh[[:space:]]+(pr|issue|run)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^gh /prltc gh /')

# --- Cargo ---
elif echo "$FIRST_CMD" | grep -qE '^cargo[[:space:]]+test([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cargo test/prltc cargo test/')
elif echo "$FIRST_CMD" | grep -qE '^cargo[[:space:]]+build([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cargo build/prltc cargo build/')
elif echo "$FIRST_CMD" | grep -qE '^cargo[[:space:]]+clippy([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cargo clippy/prltc cargo clippy/')

# --- File operations ---
elif echo "$FIRST_CMD" | grep -qE '^cat[[:space:]]+'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cat /prltc read /')
elif echo "$FIRST_CMD" | grep -qE '^(rg|grep)[[:space:]]+'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(rg|grep) /prltc grep /')
elif echo "$FIRST_CMD" | grep -qE '^ls([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^ls/prltc ls/')

# --- JS/TS tooling ---
elif echo "$FIRST_CMD" | grep -qE '^(pnpm[[:space:]]+)?vitest([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(pnpm )?vitest/prltc vitest run/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm[[:space:]]+test([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm test/prltc vitest run/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm[[:space:]]+tsc([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm tsc/prltc tsc/')
elif echo "$FIRST_CMD" | grep -qE '^(npx[[:space:]]+)?tsc([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?tsc/prltc tsc/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm[[:space:]]+lint([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm lint/prltc lint/')
elif echo "$FIRST_CMD" | grep -qE '^(npx[[:space:]]+)?eslint([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?eslint/prltc lint/')
elif echo "$FIRST_CMD" | grep -qE '^(npx[[:space:]]+)?prettier([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?prettier/prltc prettier/')
elif echo "$FIRST_CMD" | grep -qE '^(npx[[:space:]]+)?playwright([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?playwright/prltc playwright/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm[[:space:]]+playwright([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm playwright/prltc playwright/')
elif echo "$FIRST_CMD" | grep -qE '^(npx[[:space:]]+)?prisma([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?prisma/prltc prisma/')

# --- Containers ---
elif echo "$FIRST_CMD" | grep -qE '^docker[[:space:]]+(ps|images|logs)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^docker /prltc docker /')
elif echo "$FIRST_CMD" | grep -qE '^kubectl[[:space:]]+(get|logs)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^kubectl /prltc kubectl /')

# --- Network ---
elif echo "$FIRST_CMD" | grep -qE '^curl[[:space:]]+'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^curl /prltc curl /')

# --- pnpm package management ---
elif echo "$FIRST_CMD" | grep -qE '^pnpm[[:space:]]+(list|ls|outdated)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm /prltc pnpm /')

# --- Python tooling ---
elif echo "$FIRST_CMD" | grep -qE '^pytest([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pytest/prltc pytest/')
elif echo "$FIRST_CMD" | grep -qE '^python[[:space:]]+-m[[:space:]]+pytest([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^python -m pytest/prltc pytest/')
elif echo "$FIRST_CMD" | grep -qE '^ruff[[:space:]]+(check|format)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^ruff /prltc ruff /')
elif echo "$FIRST_CMD" | grep -qE '^pip[[:space:]]+(list|outdated|install|show)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pip /prltc pip /')
elif echo "$FIRST_CMD" | grep -qE '^uv[[:space:]]+pip[[:space:]]+(list|outdated|install|show)([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^uv pip /prltc pip /')

# --- Go tooling ---
elif echo "$FIRST_CMD" | grep -qE '^go[[:space:]]+test([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^go test/prltc go test/')
elif echo "$FIRST_CMD" | grep -qE '^go[[:space:]]+build([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^go build/prltc go build/')
elif echo "$FIRST_CMD" | grep -qE '^go[[:space:]]+vet([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^go vet/prltc go vet/')
elif echo "$FIRST_CMD" | grep -qE '^golangci-lint([[:space:]]|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^golangci-lint/prltc golangci-lint/')
fi

# If no rewrite needed, approve as-is
if [ -z "$REWRITTEN" ]; then
  exit 0
fi

# Build the updated tool_input with all original fields preserved, only command changed
ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '.command = $cmd')

# Output the rewrite instruction
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
