#!/usr/bin/env bash
#
# PRLTC Smoke Tests — Aristote Project (Vite + React + TS + ESLint)
# Tests PRLTC commands in a real JS/TS project context.
# Usage: bash scripts/test-aristote.sh
#
set -euo pipefail

ARISTOTE="/Users/florianbruniaux/Sites/MethodeAristote/aristote-school-boost"

PASS=0
FAIL=0
SKIP=0
FAILURES=()

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

assert_ok() {
    local name="$1"; shift
    local output
    if output=$("$@" 2>&1); then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        cmd: %s\n" "$*"
        printf "        out: %s\n" "$(echo "$output" | head -3)"
    fi
}

assert_contains() {
    local name="$1"; local needle="$2"; shift 2
    local output
    if output=$("$@" 2>&1) && echo "$output" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        expected: '%s'\n" "$needle"
        printf "        got: %s\n" "$(echo "$output" | head -3)"
    fi
}

# Allow non-zero exit but check output
assert_output() {
    local name="$1"; local needle="$2"; shift 2
    local output
    output=$("$@" 2>&1) || true
    if echo "$output" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        expected: '%s'\n" "$needle"
        printf "        got: %s\n" "$(echo "$output" | head -3)"
    fi
}

skip_test() {
    local name="$1"; local reason="$2"
    SKIP=$((SKIP + 1))
    printf "  ${YELLOW}SKIP${NC}  %s (%s)\n" "$name" "$reason"
}

section() {
    printf "\n${BOLD}${CYAN}── %s ──${NC}\n" "$1"
}

# ── Preamble ─────────────────────────────────────────

PRLTC=$(command -v prltc || echo "")
if [[ -z "$PRLTC" ]]; then
    echo "prltc not found in PATH. Run: cargo install --path ."
    exit 1
fi

if [[ ! -d "$ARISTOTE" ]]; then
    echo "Aristote project not found at $ARISTOTE"
    exit 1
fi

printf "${BOLD}PRLTC Smoke Tests — Aristote Project${NC}\n"
printf "Binary: %s (%s)\n" "$PRLTC" "$(prltc --version)"
printf "Project: %s\n" "$ARISTOTE"
printf "Date: %s\n\n" "$(date '+%Y-%m-%d %H:%M')"

# ── 1. File exploration ──────────────────────────────

section "Ls & Find"

assert_ok       "prltc ls project root"           prltc ls "$ARISTOTE"
assert_ok       "prltc ls src/"                   prltc ls "$ARISTOTE/src"
assert_ok       "prltc ls --depth 3"              prltc ls --depth 3 "$ARISTOTE/src"
assert_contains "prltc ls shows components/"      "components" prltc ls "$ARISTOTE/src"
assert_ok       "prltc find *.tsx"                prltc find "*.tsx" "$ARISTOTE/src"
assert_ok       "prltc find *.ts"                 prltc find "*.ts" "$ARISTOTE/src"
assert_contains "prltc find finds App.tsx"        "App.tsx" prltc find "*.tsx" "$ARISTOTE/src"

# ── 2. Read ──────────────────────────────────────────

section "Read"

assert_ok       "prltc read tsconfig.json"        prltc read "$ARISTOTE/tsconfig.json"
assert_ok       "prltc read package.json"         prltc read "$ARISTOTE/package.json"
assert_ok       "prltc read App.tsx"              prltc read "$ARISTOTE/src/App.tsx"
assert_ok       "prltc read --level aggressive"   prltc read --level aggressive "$ARISTOTE/src/App.tsx"
assert_ok       "prltc read --max-lines 10"       prltc read --max-lines 10 "$ARISTOTE/src/App.tsx"

# ── 3. Grep ──────────────────────────────────────────

section "Grep"

assert_ok       "prltc grep import"               prltc grep "import" "$ARISTOTE/src"
assert_ok       "prltc grep with type filter"     prltc grep "useState" "$ARISTOTE/src" -t tsx
assert_contains "prltc grep finds components"     "import" prltc grep "import" "$ARISTOTE/src"

# ── 4. Git ───────────────────────────────────────────

section "Git (in Aristote repo)"

# prltc git doesn't support -C, use git -C via subshell
assert_ok       "prltc git status"                bash -c "cd $ARISTOTE && prltc git status"
assert_ok       "prltc git log"                   bash -c "cd $ARISTOTE && prltc git log"
assert_ok       "prltc git branch"                bash -c "cd $ARISTOTE && prltc git branch"

# ── 5. Deps ──────────────────────────────────────────

section "Deps"

assert_ok       "prltc deps"                      prltc deps "$ARISTOTE"
assert_contains "prltc deps shows package.json"   "package.json" prltc deps "$ARISTOTE"

# ── 6. Json ──────────────────────────────────────────

section "Json"

assert_ok       "prltc json tsconfig"             prltc json "$ARISTOTE/tsconfig.json"
assert_ok       "prltc json package.json"         prltc json "$ARISTOTE/package.json"

# ── 7. Env ───────────────────────────────────────────

section "Env"

assert_ok       "prltc env"                       prltc env
assert_ok       "prltc env --filter NODE"         prltc env --filter NODE

# ── 8. Tsc ───────────────────────────────────────────

section "TypeScript (tsc)"

if command -v npx >/dev/null 2>&1 && [[ -d "$ARISTOTE/node_modules" ]]; then
    assert_output "prltc tsc (in aristote)" "error\|✅\|TS" prltc tsc --project "$ARISTOTE"
else
    skip_test "prltc tsc" "node_modules not installed"
fi

# ── 9. ESLint ────────────────────────────────────────

section "ESLint (lint)"

if command -v npx >/dev/null 2>&1 && [[ -d "$ARISTOTE/node_modules" ]]; then
    assert_output "prltc lint (in aristote)" "error\|warning\|✅\|violations\|clean" prltc lint --project "$ARISTOTE"
else
    skip_test "prltc lint" "node_modules not installed"
fi

# ── 10. Build (Vite) ─────────────────────────────────

section "Build (Vite via prltc next)"

if [[ -d "$ARISTOTE/node_modules" ]]; then
    # Aristote uses Vite, not Next — but prltc next wraps the build script
    # Test with a timeout since builds can be slow
    skip_test "prltc next build" "Vite project, not Next.js — use npm run build directly"
else
    skip_test "prltc next build" "node_modules not installed"
fi

# ── 11. Diff ─────────────────────────────────────────

section "Diff"

# Diff two config files that exist in the project
assert_ok       "prltc diff tsconfigs"            prltc diff "$ARISTOTE/tsconfig.json" "$ARISTOTE/tsconfig.app.json"

# ── 12. Summary & Err ────────────────────────────────

section "Summary & Err"

assert_ok       "prltc summary ls"                prltc summary ls "$ARISTOTE/src"
assert_ok       "prltc err ls"                    prltc err ls "$ARISTOTE/src"

# ── 13. Gain ─────────────────────────────────────────

section "Gain (after above commands)"

assert_ok       "prltc gain"                      prltc gain
assert_ok       "prltc gain --history"            prltc gain --history

# ══════════════════════════════════════════════════════
# Report
# ══════════════════════════════════════════════════════

printf "\n${BOLD}══════════════════════════════════════${NC}\n"
printf "${BOLD}Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d skipped${NC}\n" "$PASS" "$FAIL" "$SKIP"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    printf "\n${RED}Failures:${NC}\n"
    for f in "${FAILURES[@]}"; do
        printf "  - %s\n" "$f"
    done
fi

printf "${BOLD}══════════════════════════════════════${NC}\n"

exit "$FAIL"
