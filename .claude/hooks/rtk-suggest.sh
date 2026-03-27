#!/bin/bash
# PRLTC suggest hook for Claude Code PreToolUse:Bash
# Emits system reminders when prltc-compatible commands are detected.
# Outputs JSON with systemMessage to inform Claude Code without modifying execution.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

# Extract the first meaningful command (before pipes, &&, etc.)
FIRST_CMD="$CMD"

# Skip if already using prltc
case "$FIRST_CMD" in
  prltc\ *|*/prltc\ *) exit 0 ;;
esac

# Skip commands with heredocs, variable assignments, etc.
case "$FIRST_CMD" in
  *'<<'*) exit 0 ;;
esac

SUGGESTION=""

# --- Git commands ---
if echo "$FIRST_CMD" | grep -qE '^git\s+status(\s|$)'; then
  SUGGESTION="prltc git status"
elif echo "$FIRST_CMD" | grep -qE '^git\s+diff(\s|$)'; then
  SUGGESTION="prltc git diff"
elif echo "$FIRST_CMD" | grep -qE '^git\s+log(\s|$)'; then
  SUGGESTION="prltc git log"
elif echo "$FIRST_CMD" | grep -qE '^git\s+add(\s|$)'; then
  SUGGESTION="prltc git add"
elif echo "$FIRST_CMD" | grep -qE '^git\s+commit(\s|$)'; then
  SUGGESTION="prltc git commit"
elif echo "$FIRST_CMD" | grep -qE '^git\s+push(\s|$)'; then
  SUGGESTION="prltc git push"
elif echo "$FIRST_CMD" | grep -qE '^git\s+pull(\s|$)'; then
  SUGGESTION="prltc git pull"
elif echo "$FIRST_CMD" | grep -qE '^git\s+branch(\s|$)'; then
  SUGGESTION="prltc git branch"
elif echo "$FIRST_CMD" | grep -qE '^git\s+fetch(\s|$)'; then
  SUGGESTION="prltc git fetch"
elif echo "$FIRST_CMD" | grep -qE '^git\s+stash(\s|$)'; then
  SUGGESTION="prltc git stash"
elif echo "$FIRST_CMD" | grep -qE '^git\s+show(\s|$)'; then
  SUGGESTION="prltc git show"

# --- GitHub CLI ---
elif echo "$FIRST_CMD" | grep -qE '^gh\s+(pr|issue|run)(\s|$)'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^gh /prltc gh /')

# --- Cargo ---
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+test(\s|$)'; then
  SUGGESTION="prltc cargo test"
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+build(\s|$)'; then
  SUGGESTION="prltc cargo build"
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+clippy(\s|$)'; then
  SUGGESTION="prltc cargo clippy"
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+check(\s|$)'; then
  SUGGESTION="prltc cargo check"
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+install(\s|$)'; then
  SUGGESTION="prltc cargo install"
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+nextest(\s|$)'; then
  SUGGESTION="prltc cargo nextest"
elif echo "$FIRST_CMD" | grep -qE '^cargo\s+fmt(\s|$)'; then
  SUGGESTION="prltc cargo fmt"

# --- File operations ---
elif echo "$FIRST_CMD" | grep -qE '^cat\s+'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^cat /prltc read /')
elif echo "$FIRST_CMD" | grep -qE '^(rg|grep)\s+'; then
  SUGGESTION=$(echo "$CMD" | sed -E 's/^(rg|grep) /prltc grep /')
elif echo "$FIRST_CMD" | grep -qE '^ls(\s|$)'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^ls/prltc ls/')
elif echo "$FIRST_CMD" | grep -qE '^tree(\s|$)'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^tree/prltc tree/')
elif echo "$FIRST_CMD" | grep -qE '^find\s+'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^find /prltc find /')
elif echo "$FIRST_CMD" | grep -qE '^diff\s+'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^diff /prltc diff /')
elif echo "$FIRST_CMD" | grep -qE '^head\s+'; then
  # Suggest prltc read with --max-lines transformation
  if echo "$FIRST_CMD" | grep -qE '^head\s+-[0-9]+\s+'; then
    LINES=$(echo "$FIRST_CMD" | sed -E 's/^head +-([0-9]+) +.+$/\1/')
    FILE=$(echo "$FIRST_CMD" | sed -E 's/^head +-[0-9]+ +(.+)$/\1/')
    SUGGESTION="prltc read $FILE --max-lines $LINES"
  elif echo "$FIRST_CMD" | grep -qE '^head\s+--lines=[0-9]+\s+'; then
    LINES=$(echo "$FIRST_CMD" | sed -E 's/^head +--lines=([0-9]+) +.+$/\1/')
    FILE=$(echo "$FIRST_CMD" | sed -E 's/^head +--lines=[0-9]+ +(.+)$/\1/')
    SUGGESTION="prltc read $FILE --max-lines $LINES"
  fi

# --- JS/TS tooling ---
elif echo "$FIRST_CMD" | grep -qE '^(pnpm\s+)?vitest(\s|$)'; then
  SUGGESTION="prltc vitest run"
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+test(\s|$)'; then
  SUGGESTION="prltc vitest run"
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+tsc(\s|$)'; then
  SUGGESTION="prltc tsc"
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?tsc(\s|$)'; then
  SUGGESTION="prltc tsc"
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+lint(\s|$)'; then
  SUGGESTION="prltc lint"
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?eslint(\s|$)'; then
  SUGGESTION="prltc lint"
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?prettier(\s|$)'; then
  SUGGESTION="prltc prettier"
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?playwright(\s|$)'; then
  SUGGESTION="prltc playwright"
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+playwright(\s|$)'; then
  SUGGESTION="prltc playwright"
elif echo "$FIRST_CMD" | grep -qE '^(npx\s+)?prisma(\s|$)'; then
  SUGGESTION="prltc prisma"

# --- Containers ---
elif echo "$FIRST_CMD" | grep -qE '^docker\s+(ps|images|logs)(\s|$)'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^docker /prltc docker /')
elif echo "$FIRST_CMD" | grep -qE '^kubectl\s+(get|logs)(\s|$)'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^kubectl /prltc kubectl /')

# --- Network ---
elif echo "$FIRST_CMD" | grep -qE '^curl\s+'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^curl /prltc curl /')
elif echo "$FIRST_CMD" | grep -qE '^wget\s+'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^wget /prltc wget /')

# --- pnpm package management ---
elif echo "$FIRST_CMD" | grep -qE '^pnpm\s+(list|ls|outdated)(\s|$)'; then
  SUGGESTION=$(echo "$CMD" | sed 's/^pnpm /prltc pnpm /')
fi

# If no suggestion, allow command as-is
if [ -z "$SUGGESTION" ]; then
  exit 0
fi

# Output suggestion as system message
jq -n \
  --arg suggestion "$SUGGESTION" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "systemMessage": ("⚡ PRLTC available: `" + $suggestion + "` (60-90% token savings)")
    }
  }'
