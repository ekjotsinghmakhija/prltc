#!/bin/bash
# Test suite for prltc-rewrite.sh
# Feeds mock JSON through the hook and verifies the rewritten commands.
#
# Usage: bash ~/.claude/hooks/test-prltc-rewrite.sh

HOOK="${HOOK:-$HOME/.claude/hooks/prltc-rewrite.sh}"
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[32m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

test_rewrite() {
  local description="$1"
  local input_cmd="$2"
  local expected_cmd="$3"  # empty string = expect no rewrite
  TOTAL=$((TOTAL + 1))

  local input_json
  input_json=$(jq -n --arg cmd "$input_cmd" '{"tool_name":"Bash","tool_input":{"command":$cmd}}')
  local output
  output=$(echo "$input_json" | bash "$HOOK" 2>/dev/null) || true

  if [ -z "$expected_cmd" ]; then
    # Expect no rewrite (hook exits 0 with no output)
    if [ -z "$output" ]; then
      printf "  ${GREEN}PASS${RESET} %s ${DIM}→ (no rewrite)${RESET}\n" "$description"
      PASS=$((PASS + 1))
    else
      local actual
      actual=$(echo "$output" | jq -r '.hookSpecificOutput.updatedInput.command // empty')
      printf "  ${RED}FAIL${RESET} %s\n" "$description"
      printf "       expected: (no rewrite)\n"
      printf "       actual:   %s\n" "$actual"
      FAIL=$((FAIL + 1))
    fi
  else
    local actual
    actual=$(echo "$output" | jq -r '.hookSpecificOutput.updatedInput.command // empty' 2>/dev/null)
    if [ "$actual" = "$expected_cmd" ]; then
      printf "  ${GREEN}PASS${RESET} %s ${DIM}→ %s${RESET}\n" "$description" "$actual"
      PASS=$((PASS + 1))
    else
      printf "  ${RED}FAIL${RESET} %s\n" "$description"
      printf "       expected: %s\n" "$expected_cmd"
      printf "       actual:   %s\n" "$actual"
      FAIL=$((FAIL + 1))
    fi
  fi
}

echo "============================================"
echo "  PRLTC Rewrite Hook Test Suite"
echo "============================================"
echo ""

# ---- SECTION 1: Existing patterns (regression tests) ----
echo "--- Existing patterns (regression) ---"
test_rewrite "git status" \
  "git status" \
  "prltc git status"

test_rewrite "git log --oneline -10" \
  "git log --oneline -10" \
  "prltc git log --oneline -10"

test_rewrite "git diff HEAD" \
  "git diff HEAD" \
  "prltc git diff HEAD"

test_rewrite "git show abc123" \
  "git show abc123" \
  "prltc git show abc123"

test_rewrite "git add ." \
  "git add ." \
  "prltc git add ."

test_rewrite "gh pr list" \
  "gh pr list" \
  "prltc gh pr list"

test_rewrite "npx playwright test" \
  "npx playwright test" \
  "prltc playwright test"

test_rewrite "ls -la" \
  "ls -la" \
  "prltc ls -la"

test_rewrite "curl -s https://example.com" \
  "curl -s https://example.com" \
  "prltc curl -s https://example.com"

test_rewrite "cat package.json" \
  "cat package.json" \
  "prltc read package.json"

test_rewrite "grep -rn pattern src/" \
  "grep -rn pattern src/" \
  "prltc grep -rn pattern src/"

test_rewrite "rg pattern src/" \
  "rg pattern src/" \
  "prltc grep pattern src/"

test_rewrite "cargo test" \
  "cargo test" \
  "prltc cargo test"

test_rewrite "npx prisma migrate" \
  "npx prisma migrate" \
  "prltc prisma migrate"

echo ""

# ---- SECTION 2: Env var prefix handling (THE BIG FIX) ----
echo "--- Env var prefix handling (new) ---"
test_rewrite "env + playwright" \
  "TEST_SESSION_ID=2 npx playwright test --config=foo" \
  "TEST_SESSION_ID=2 prltc playwright test --config=foo"

test_rewrite "env + git status" \
  "GIT_PAGER=cat git status" \
  "GIT_PAGER=cat prltc git status"

test_rewrite "env + git log" \
  "GIT_PAGER=cat git log --oneline -10" \
  "GIT_PAGER=cat prltc git log --oneline -10"

test_rewrite "multi env + vitest" \
  "NODE_ENV=test CI=1 npx vitest run" \
  "NODE_ENV=test CI=1 prltc vitest run"

test_rewrite "env + ls" \
  "LANG=C ls -la" \
  "LANG=C prltc ls -la"

test_rewrite "env + npm run" \
  "NODE_ENV=test npm run test:e2e" \
  "NODE_ENV=test prltc npm test:e2e"

test_rewrite "env + docker compose" \
  "COMPOSE_PROJECT_NAME=test docker compose up -d" \
  "COMPOSE_PROJECT_NAME=test prltc docker compose up -d"

echo ""

# ---- SECTION 3: New patterns ----
echo "--- New patterns ---"
test_rewrite "npm run test:e2e" \
  "npm run test:e2e" \
  "prltc npm test:e2e"

test_rewrite "npm run build" \
  "npm run build" \
  "prltc npm build"

test_rewrite "npm test" \
  "npm test" \
  "prltc npm test"

test_rewrite "vue-tsc -b" \
  "vue-tsc -b" \
  "prltc tsc -b"

test_rewrite "npx vue-tsc --noEmit" \
  "npx vue-tsc --noEmit" \
  "prltc tsc --noEmit"

test_rewrite "docker compose up -d" \
  "docker compose up -d" \
  "prltc docker compose up -d"

test_rewrite "docker compose logs postgrest" \
  "docker compose logs postgrest" \
  "prltc docker compose logs postgrest"

test_rewrite "docker compose down" \
  "docker compose down" \
  "prltc docker compose down"

test_rewrite "docker run --rm postgres" \
  "docker run --rm postgres" \
  "prltc docker run --rm postgres"

test_rewrite "docker exec -it db psql" \
  "docker exec -it db psql" \
  "prltc docker exec -it db psql"

test_rewrite "find (NOT rewritten — different arg format)" \
  "find . -name '*.ts'" \
  ""

test_rewrite "tree (NOT rewritten — different arg format)" \
  "tree src/" \
  ""

test_rewrite "wget (NOT rewritten — different arg format)" \
  "wget https://example.com/file" \
  ""

test_rewrite "gh api repos/owner/repo" \
  "gh api repos/owner/repo" \
  "prltc gh api repos/owner/repo"

test_rewrite "gh release list" \
  "gh release list" \
  "prltc gh release list"

test_rewrite "kubectl describe pod foo" \
  "kubectl describe pod foo" \
  "prltc kubectl describe pod foo"

test_rewrite "kubectl apply -f deploy.yaml" \
  "kubectl apply -f deploy.yaml" \
  "prltc kubectl apply -f deploy.yaml"

echo ""

# ---- SECTION 4: Vitest edge case (fixed double "run" bug) ----
echo "--- Vitest run dedup ---"
test_rewrite "vitest (no args)" \
  "vitest" \
  "prltc vitest run"

test_rewrite "vitest run (no double run)" \
  "vitest run" \
  "prltc vitest run"

test_rewrite "vitest run --reporter" \
  "vitest run --reporter=verbose" \
  "prltc vitest run --reporter=verbose"

test_rewrite "npx vitest run" \
  "npx vitest run" \
  "prltc vitest run"

test_rewrite "pnpm vitest run --coverage" \
  "pnpm vitest run --coverage" \
  "prltc vitest run --coverage"

echo ""

# ---- SECTION 5: Should NOT rewrite ----
echo "--- Should NOT rewrite ---"
test_rewrite "already prltc" \
  "prltc git status" \
  ""

test_rewrite "heredoc" \
  "cat <<'EOF'
hello
EOF" \
  ""

test_rewrite "echo (no pattern)" \
  "echo hello world" \
  ""

test_rewrite "cd (no pattern)" \
  "cd /tmp" \
  ""

test_rewrite "mkdir (no pattern)" \
  "mkdir -p foo/bar" \
  ""

test_rewrite "python3 (no pattern)" \
  "python3 script.py" \
  ""

test_rewrite "node (no pattern)" \
  "node -e 'console.log(1)'" \
  ""

echo ""

# ---- SECTION 6: Audit logging ----
echo "--- Audit logging (PRLTC_HOOK_AUDIT=1) ---"

AUDIT_TMPDIR=$(mktemp -d)
trap "rm -rf $AUDIT_TMPDIR" EXIT

test_audit_log() {
  local description="$1"
  local input_cmd="$2"
  local expected_action="$3"
  TOTAL=$((TOTAL + 1))

  # Clean log
  rm -f "$AUDIT_TMPDIR/hook-audit.log"

  local input_json
  input_json=$(jq -n --arg cmd "$input_cmd" '{"tool_name":"Bash","tool_input":{"command":$cmd}}')
  echo "$input_json" | PRLTC_HOOK_AUDIT=1 PRLTC_AUDIT_DIR="$AUDIT_TMPDIR" bash "$HOOK" 2>/dev/null || true

  if [ ! -f "$AUDIT_TMPDIR/hook-audit.log" ]; then
    printf "  ${RED}FAIL${RESET} %s (no log file created)\n" "$description"
    FAIL=$((FAIL + 1))
    return
  fi

  local log_line
  log_line=$(head -1 "$AUDIT_TMPDIR/hook-audit.log")
  local actual_action
  actual_action=$(echo "$log_line" | cut -d'|' -f2 | tr -d ' ')

  if [ "$actual_action" = "$expected_action" ]; then
    printf "  ${GREEN}PASS${RESET} %s ${DIM}→ %s${RESET}\n" "$description" "$actual_action"
    PASS=$((PASS + 1))
  else
    printf "  ${RED}FAIL${RESET} %s\n" "$description"
    printf "       expected action: %s\n" "$expected_action"
    printf "       actual action:   %s\n" "$actual_action"
    printf "       log line:        %s\n" "$log_line"
    FAIL=$((FAIL + 1))
  fi
}

test_audit_log "audit: rewrite git status" \
  "git status" \
  "rewrite"

test_audit_log "audit: skip already_prltc" \
  "prltc git status" \
  "skip:already_prltc"

test_audit_log "audit: skip heredoc" \
  "cat <<'EOF'
hello
EOF" \
  "skip:heredoc"

test_audit_log "audit: skip no_match" \
  "echo hello world" \
  "skip:no_match"

test_audit_log "audit: rewrite cargo test" \
  "cargo test" \
  "rewrite"

# Test log format (4 pipe-separated fields)
rm -f "$AUDIT_TMPDIR/hook-audit.log"
input_json=$(jq -n --arg cmd "git status" '{"tool_name":"Bash","tool_input":{"command":$cmd}}')
echo "$input_json" | PRLTC_HOOK_AUDIT=1 PRLTC_AUDIT_DIR="$AUDIT_TMPDIR" bash "$HOOK" 2>/dev/null || true
TOTAL=$((TOTAL + 1))
log_line=$(cat "$AUDIT_TMPDIR/hook-audit.log" 2>/dev/null || echo "")
field_count=$(echo "$log_line" | awk -F' \\| ' '{print NF}')
if [ "$field_count" = "4" ]; then
  printf "  ${GREEN}PASS${RESET} audit: log format has 4 fields ${DIM}→ %s${RESET}\n" "$log_line"
  PASS=$((PASS + 1))
else
  printf "  ${RED}FAIL${RESET} audit: log format (expected 4 fields, got %s)\n" "$field_count"
  printf "       log line: %s\n" "$log_line"
  FAIL=$((FAIL + 1))
fi

# Test no log when PRLTC_HOOK_AUDIT is unset
rm -f "$AUDIT_TMPDIR/hook-audit.log"
input_json=$(jq -n --arg cmd "git status" '{"tool_name":"Bash","tool_input":{"command":$cmd}}')
echo "$input_json" | PRLTC_AUDIT_DIR="$AUDIT_TMPDIR" bash "$HOOK" 2>/dev/null || true
TOTAL=$((TOTAL + 1))
if [ ! -f "$AUDIT_TMPDIR/hook-audit.log" ]; then
  printf "  ${GREEN}PASS${RESET} audit: no log when PRLTC_HOOK_AUDIT unset\n"
  PASS=$((PASS + 1))
else
  printf "  ${RED}FAIL${RESET} audit: log created when PRLTC_HOOK_AUDIT unset\n"
  FAIL=$((FAIL + 1))
fi

echo ""

# ---- SUMMARY ----
echo "============================================"
if [ $FAIL -eq 0 ]; then
  printf "  ${GREEN}ALL $TOTAL TESTS PASSED${RESET}\n"
else
  printf "  ${RED}$FAIL FAILED${RESET} / $TOTAL total ($PASS passed)\n"
fi
echo "============================================"

exit $FAIL
