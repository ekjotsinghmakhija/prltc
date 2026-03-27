#!/bin/bash
# PRLTC auto-rewrite hook for Claude Code PreToolUse:Bash
# Transparently rewrites raw commands to their prltc equivalents.
# Outputs JSON with updatedInput to modify the command before execution.

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
if echo "$FIRST_CMD" | grep -qE '^git\s+status(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git status/prltc git status/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+diff(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git diff/prltc git diff/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+log(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git log/prltc git log/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+add(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git add/prltc git add/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+commit(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git commit/prltc git commit/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+push(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git push/prltc git push/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+pull(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git pull/prltc git pull/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+branch(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git branch/prltc git branch/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+fetch(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git fetch/prltc git fetch/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+stash(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git stash/prltc git stash/')
elif echo "$FIRST_CMD" | grep -qE '^git\s+show(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^git show/prltc git show/')

# --- GitHub CLI ---
elif echo "$FIRST_CMD" | grep -qE '^gh\s+(pr|issue|run)(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^gh /prltc gh /')

# --- Cargo ---
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+test(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cargo test/prltc cargo test/')
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+build(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cargo build/prltc cargo build/')
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+clippy(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cargo clippy/prltc cargo clippy/')

# --- File operations ---
elif echo "$FIRST_CMD" | grep -qE '^cat\s+'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^cat /prltc read /')
elif echo "$FIRST_CMD" | grep -qE '^(rg|grep)\s+'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(rg|grep) /prltc grep /')
elif echo "$FIRST_CMD" | grep -qE '^ls(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^ls/prltc ls/')

# --- JS/TS tooling ---
elif echo "$FIRST_CMD" | grep -qE '^(pnpm\s+)?vitest(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(pnpm )?vitest/prltc vitest run/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+test(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm test/prltc vitest run/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+tsc(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm tsc/prltc tsc/')
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?tsc(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?tsc/prltc tsc/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+lint(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm lint/prltc lint/')
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?eslint(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?eslint/prltc lint/')
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?prettier(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?prettier/prltc prettier/')
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?playwright(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?playwright/prltc playwright/')
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+playwright(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm playwright/prltc playwright/')
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?prisma(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed -E 's/^(npx )?prisma/prltc prisma/')

# --- Containers ---
elif echo "$FIRST_CMD" | grep -qE '^docker\s+(ps|images|logs)(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^docker /prltc docker /')
elif echo "$FIRST_CMD" | grep -qE '^kubectl\s+(get|logs)(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^kubectl /prltc kubectl /')

# --- Network ---
elif echo "$FIRST_CMD" | grep -qE '^curl\s+'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^curl /prltc curl /')

# --- pnpm package management ---
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+(list|ls|outdated)(\s|$)'; then
  REWRITTEN=$(echo "$CMD" | sed 's/^pnpm /prltc pnpm /')
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
