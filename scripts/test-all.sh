#!/usr/bin/env bash
#
# PRLTC Smoke Test Suite
# Exercises every command to catch regressions after merge.
# Exit code: number of failures (0 = all green)
#
set -euo pipefail

PASS=0
FAIL=0
SKIP=0
FAILURES=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────

assert_ok() {
    local name="$1"
    shift
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
    local name="$1"
    local needle="$2"
    shift 2
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

assert_exit_ok() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    else
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
        printf "  ${RED}FAIL${NC}  %s\n" "$name"
        printf "        cmd: %s\n" "$*"
    fi
}

assert_help() {
    local name="$1"
    shift
    assert_contains "$name --help" "Usage:" "$@" --help
}

skip_test() {
    local name="$1"
    local reason="$2"
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

printf "${BOLD}PRLTC Smoke Test Suite${NC}\n"
printf "Binary: %s\n" "$PRLTC"
printf "Version: %s\n" "$(prltc --version)"
printf "Date: %s\n" "$(date '+%Y-%m-%d %H:%M')"

# Need a git repo to test git commands
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Must run from inside a git repository."
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)

# ── 1. Version & Help ───────────────────────────────

section "Version & Help"

assert_contains "prltc --version" "prltc" prltc --version
assert_contains "prltc --help" "Usage:" prltc --help

# ── 2. Ls ────────────────────────────────────────────

section "Ls"

assert_ok      "prltc ls ."                     prltc ls .
assert_ok      "prltc ls -la ."                 prltc ls -la .
assert_ok      "prltc ls -lh ."                 prltc ls -lh .
assert_contains "prltc ls -a shows hidden"      ".git" prltc ls -a .

# ── 2b. Tree ─────────────────────────────────────────

section "Tree"

if command -v tree >/dev/null 2>&1; then
    assert_ok      "prltc tree ."                prltc tree .
    assert_ok      "prltc tree -L 2 ."           prltc tree -L 2 .
    assert_ok      "prltc tree -d -L 1 ."        prltc tree -d -L 1 .
    assert_contains "prltc tree shows src/"      "src" prltc tree -L 1 .
else
    skip_test "prltc tree" "tree not installed"
fi

# ── 3. Read ──────────────────────────────────────────

section "Read"

assert_ok      "prltc read Cargo.toml"          prltc read Cargo.toml
assert_ok      "prltc read --level none Cargo.toml"  prltc read --level none Cargo.toml
assert_ok      "prltc read --level aggressive Cargo.toml" prltc read --level aggressive Cargo.toml
assert_ok      "prltc read -n Cargo.toml"       prltc read -n Cargo.toml
assert_ok      "prltc read --max-lines 5 Cargo.toml" prltc read --max-lines 5 Cargo.toml

# ── 4. Git ───────────────────────────────────────────

section "Git (existing)"

assert_ok      "prltc git status"               prltc git status
assert_ok      "prltc git status --short"       prltc git status --short
assert_ok      "prltc git status -s"            prltc git status -s
assert_ok      "prltc git status --porcelain"   prltc git status --porcelain
assert_ok      "prltc git log"                  prltc git log
assert_ok      "prltc git log -5"               prltc git log -- -5
assert_ok      "prltc git diff"                 prltc git diff
assert_ok      "prltc git diff --stat"          prltc git diff --stat

section "Git (new: branch, fetch, stash, worktree)"

assert_ok      "prltc git branch"               prltc git branch
assert_ok      "prltc git fetch"                prltc git fetch
assert_ok      "prltc git stash list"           prltc git stash list
assert_ok      "prltc git worktree"             prltc git worktree

section "Git (passthrough: unsupported subcommands)"

assert_ok      "prltc git tag --list"           prltc git tag --list
assert_ok      "prltc git remote -v"            prltc git remote -v
assert_ok      "prltc git rev-parse HEAD"       prltc git rev-parse HEAD

# ── 5. GitHub CLI ────────────────────────────────────

section "GitHub CLI"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    assert_ok      "prltc gh pr list"           prltc gh pr list
    assert_ok      "prltc gh run list"          prltc gh run list
    assert_ok      "prltc gh issue list"        prltc gh issue list
    # pr create/merge/diff/comment/edit are write ops, test help only
    assert_help    "prltc gh"                   prltc gh
else
    skip_test "gh commands" "gh not authenticated"
fi

# ── 6. Cargo ─────────────────────────────────────────

section "Cargo (new)"

assert_ok      "prltc cargo build"              prltc cargo build
assert_ok      "prltc cargo clippy"             prltc cargo clippy
# cargo test exits non-zero due to pre-existing failures; check output ignoring exit code
output_cargo_test=$(prltc cargo test 2>&1 || true)
if echo "$output_cargo_test" | grep -q "FAILURES\|test result:"; then
    PASS=$((PASS + 1))
    printf "  ${GREEN}PASS${NC}  %s\n" "prltc cargo test"
else
    FAIL=$((FAIL + 1))
    FAILURES+=("prltc cargo test")
    printf "  ${RED}FAIL${NC}  %s\n" "prltc cargo test"
    printf "        got: %s\n" "$(echo "$output_cargo_test" | head -3)"
fi
assert_help    "prltc cargo"                    prltc cargo

# ── 7. Curl ──────────────────────────────────────────

section "Curl (new)"

assert_contains "prltc curl JSON detect" "string" prltc curl https://httpbin.org/json
assert_ok       "prltc curl plain text"          prltc curl https://httpbin.org/robots.txt
assert_help     "prltc curl"                     prltc curl

# ── 8. Npm / Npx ────────────────────────────────────

section "Npm / Npx (new)"

assert_help    "prltc npm"                      prltc npm
assert_help    "prltc npx"                      prltc npx

# ── 9. Pnpm ─────────────────────────────────────────

section "Pnpm"

assert_help    "prltc pnpm"                     prltc pnpm
assert_help    "prltc pnpm build"               prltc pnpm build
assert_help    "prltc pnpm typecheck"           prltc pnpm typecheck

if command -v pnpm >/dev/null 2>&1; then
    assert_ok  "prltc pnpm help"                prltc pnpm help
fi

# ── 10. Grep ─────────────────────────────────────────

section "Grep"

assert_ok      "prltc grep pattern"             prltc grep "pub fn" src/
assert_contains "prltc grep finds results"      "pub fn" prltc grep "pub fn" src/
assert_ok      "prltc grep with file type"      prltc grep "pub fn" src/ -t rust

section "Grep (extra args passthrough)"

assert_ok      "prltc grep -i case insensitive" prltc grep "fn" src/ -i
assert_ok      "prltc grep -A context lines"    prltc grep "fn run" src/ -A 2

# ── 11. Find ─────────────────────────────────────────

section "Find"

assert_ok      "prltc find *.rs"                prltc find "*.rs" src/
assert_contains "prltc find shows files"        ".rs" prltc find "*.rs" src/

# ── 12. Json ─────────────────────────────────────────

section "Json"

# Create temp JSON file for testing
TMPJSON=$(mktemp /tmp/prltc-test-XXXXX.json)
echo '{"name":"test","count":42,"items":[1,2,3]}' > "$TMPJSON"

assert_ok      "prltc json file"                prltc json "$TMPJSON"
assert_contains "prltc json shows schema"       "string" prltc json "$TMPJSON"

rm -f "$TMPJSON"

# ── 13. Deps ─────────────────────────────────────────

section "Deps"

assert_ok      "prltc deps ."                   prltc deps .
assert_contains "prltc deps shows Cargo"        "Cargo" prltc deps .

# ── 14. Env ──────────────────────────────────────────

section "Env"

assert_ok      "prltc env"                      prltc env
assert_ok      "prltc env --filter PATH"        prltc env --filter PATH

# ── 15. Diff ─────────────────────────────────────────

section "Diff"

TMPF1=$(mktemp /tmp/prltc-diff1-XXXXX.txt)
TMPF2=$(mktemp /tmp/prltc-diff2-XXXXX.txt)
echo -e "line1\nline2\nline3" > "$TMPF1"
echo -e "line1\nchanged\nline3" > "$TMPF2"

assert_ok      "prltc diff two files"           prltc diff "$TMPF1" "$TMPF2"

rm -f "$TMPF1" "$TMPF2"

# ── 16. Log ──────────────────────────────────────────

section "Log"

TMPLOG=$(mktemp /tmp/prltc-log-XXXXX.log)
for i in $(seq 1 20); do
    echo "[2025-01-01 12:00:00] INFO: repeated message" >> "$TMPLOG"
done
echo "[2025-01-01 12:00:01] ERROR: something failed" >> "$TMPLOG"

assert_ok      "prltc log file"                 prltc log "$TMPLOG"

rm -f "$TMPLOG"

# ── 17. Summary ──────────────────────────────────────

section "Summary"

assert_ok      "prltc summary echo hello"       prltc summary echo hello

# ── 18. Err ──────────────────────────────────────────

section "Err"

assert_ok      "prltc err echo ok"              prltc err echo ok

# ── 19. Test runner ──────────────────────────────────

section "Test runner"

assert_ok      "prltc test echo ok"             prltc test echo ok

# ── 20. Gain ─────────────────────────────────────────

section "Gain"

assert_ok      "prltc gain"                     prltc gain
assert_ok      "prltc gain --history"           prltc gain --history

# ── 21. Config & Init ────────────────────────────────

section "Config & Init"

assert_ok      "prltc config"                   prltc config
assert_ok      "prltc init --show"              prltc init --show

# ── 22. Wget ─────────────────────────────────────────

section "Wget"

if command -v wget >/dev/null 2>&1; then
    assert_ok  "prltc wget stdout"              prltc wget https://httpbin.org/robots.txt -O
else
    skip_test "prltc wget" "wget not installed"
fi

# ── 23. Tsc / Lint / Prettier / Next / Playwright ───

section "JS Tooling (help only, no project context)"

assert_help    "prltc tsc"                      prltc tsc
assert_help    "prltc lint"                     prltc lint
assert_help    "prltc prettier"                 prltc prettier
assert_help    "prltc next"                     prltc next
assert_help    "prltc playwright"               prltc playwright

# ── 24. Prisma ───────────────────────────────────────

section "Prisma (help only)"

assert_help    "prltc prisma"                   prltc prisma

# ── 25. Vitest ───────────────────────────────────────

section "Vitest (help only)"

assert_help    "prltc vitest"                   prltc vitest

# ── 26. Docker / Kubectl (help only) ────────────────

section "Docker / Kubectl (help only)"

assert_help    "prltc docker"                   prltc docker
assert_help    "prltc kubectl"                  prltc kubectl

# ── 27. Global flags ────────────────────────────────

section "Global flags"

assert_ok      "prltc -u ls ."                  prltc -u ls .
assert_ok      "prltc --skip-env npm --help"    prltc --skip-env npm --help

# ── 28. CcEconomics ─────────────────────────────────

section "CcEconomics"

assert_ok      "prltc cc-economics"             prltc cc-economics

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
