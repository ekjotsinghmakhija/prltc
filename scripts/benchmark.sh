#!/bin/bash
set -e

PRLTC="./target/release/prltc"
BENCH_DIR="./scripts/benchmark"

# Mode local : générer les fichiers debug
if [ -z "$CI" ]; then
  rm -rf "$BENCH_DIR"
  mkdir -p "$BENCH_DIR/unix" "$BENCH_DIR/prltc" "$BENCH_DIR/diff"
fi

# Nom de fichier safe
safe_name() {
  echo "$1" | tr ' /' '_-' | tr -cd 'a-zA-Z0-9_-'
}

# Fonction pour compter les tokens (~4 chars = 1 token)
count_tokens() {
  local input="$1"
  local len=${#input}
  echo $(( (len + 3) / 4 ))
}

# Compteurs globaux
TOTAL_UNIX=0
TOTAL_PRLTC=0
TOTAL_TESTS=0
GOOD_TESTS=0
FAIL_TESTS=0
SKIP_TESTS=0

# Fonction de benchmark — une ligne par test
bench() {
  local name="$1"
  local unix_cmd="$2"
  local prltc_cmd="$3"

  unix_out=$(eval "$unix_cmd" 2>/dev/null || true)
  prltc_out=$(eval "$prltc_cmd" 2>/dev/null || true)

  unix_tokens=$(count_tokens "$unix_out")
  prltc_tokens=$(count_tokens "$prltc_out")

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  local icon=""
  local tag=""

  if [ -z "$prltc_out" ]; then
    icon="❌"
    tag="FAIL"
    FAIL_TESTS=$((FAIL_TESTS + 1))
    TOTAL_UNIX=$((TOTAL_UNIX + unix_tokens))
    TOTAL_PRLTC=$((TOTAL_PRLTC + unix_tokens))
  elif [ "$prltc_tokens" -ge "$unix_tokens" ] && [ "$unix_tokens" -gt 0 ]; then
    icon="⚠️"
    tag="SKIP"
    SKIP_TESTS=$((SKIP_TESTS + 1))
    TOTAL_UNIX=$((TOTAL_UNIX + unix_tokens))
    TOTAL_PRLTC=$((TOTAL_PRLTC + unix_tokens))
  else
    icon="✅"
    tag="GOOD"
    GOOD_TESTS=$((GOOD_TESTS + 1))
    TOTAL_UNIX=$((TOTAL_UNIX + unix_tokens))
    TOTAL_PRLTC=$((TOTAL_PRLTC + prltc_tokens))
  fi

  if [ "$tag" = "FAIL" ]; then
    printf "%s %-24s │ %-40s │ %-40s │ %6d → %6s (--)\n" \
      "$icon" "$name" "$unix_cmd" "$prltc_cmd" "$unix_tokens" "-"
  else
    if [ "$unix_tokens" -gt 0 ]; then
      local pct=$(( (unix_tokens - prltc_tokens) * 100 / unix_tokens ))
    else
      local pct=0
    fi
    printf "%s %-24s │ %-40s │ %-40s │ %6d → %6d (%+d%%)\n" \
      "$icon" "$name" "$unix_cmd" "$prltc_cmd" "$unix_tokens" "$prltc_tokens" "$pct"
  fi

  # Fichiers debug en local uniquement
  if [ -z "$CI" ]; then
    local filename=$(safe_name "$name")
    local prefix="GOOD"
    [ "$tag" = "FAIL" ] && prefix="FAIL"
    [ "$tag" = "SKIP" ] && prefix="BAD"

    local ts=$(date "+%d/%m/%Y %H:%M:%S")

    printf "# %s\n> %s\n\n\`\`\`bash\n$ %s\n\`\`\`\n\n\`\`\`\n%s\n\`\`\`\n" \
      "$name" "$ts" "$unix_cmd" "$unix_out" > "$BENCH_DIR/unix/${filename}.md"

    printf "# %s\n> %s\n\n\`\`\`bash\n$ %s\n\`\`\`\n\n\`\`\`\n%s\n\`\`\`\n" \
      "$name" "$ts" "$prltc_cmd" "$prltc_out" > "$BENCH_DIR/prltc/${filename}.md"

    {
      echo "# Diff: $name"
      echo "> $ts"
      echo ""
      echo "| Metric | Unix | PRLTC |"
      echo "|--------|------|-----|"
      echo "| Tokens | $unix_tokens | $prltc_tokens |"
      echo ""
      echo "## Unix"
      echo "\`\`\`"
      echo "$unix_out"
      echo "\`\`\`"
      echo ""
      echo "## PRLTC"
      echo "\`\`\`"
      echo "$prltc_out"
      echo "\`\`\`"
    } > "$BENCH_DIR/diff/${prefix}-${filename}.md"
  fi
}

# Section header
section() {
  echo ""
  echo "── $1 ──"
}

# ═══════════════════════════════════════════
echo "PRLTC Benchmark"
echo "═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════"
printf "   %-24s │ %-40s │ %-40s │ %s\n" "TEST" "SHELL" "PRLTC" "TOKENS"
echo "───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"

# ===================
# ls
# ===================
section "ls"
bench "ls" "ls -la" "$PRLTC ls"
bench "ls src/" "ls -la src/" "$PRLTC ls src/"
bench "ls -l src/" "ls -l src/" "$PRLTC ls -l src/"
bench "ls -la src/" "ls -la src/" "$PRLTC ls -la src/"
bench "ls -lh src/" "ls -lh src/" "$PRLTC ls -lh src/"
bench "ls src/ -l" "ls -l src/" "$PRLTC ls src/ -l"
bench "ls -a" "ls -la" "$PRLTC ls -a"
bench "ls multi" "ls -la src/ scripts/" "$PRLTC ls src/ scripts/"

# ===================
# read
# ===================
section "read"
bench "read" "cat src/main.rs" "$PRLTC read src/main.rs"
bench "read -l minimal" "cat src/main.rs" "$PRLTC read src/main.rs -l minimal"
bench "read -l aggressive" "cat src/main.rs" "$PRLTC read src/main.rs -l aggressive"
bench "read -n" "cat -n src/main.rs" "$PRLTC read src/main.rs -n"

# ===================
# find
# ===================
section "find"
bench "find *" "find . -type f" "$PRLTC find '*'"
bench "find *.rs" "find . -name '*.rs' -type f" "$PRLTC find '*.rs'"
bench "find --max 10" "find . -not -path './target/*' -not -path './.git/*' -type f | head -10" "$PRLTC find '*' --max 10"
bench "find --max 100" "find . -not -path './target/*' -not -path './.git/*' -type f | head -100" "$PRLTC find '*' --max 100"

# ===================
# git
# ===================
section "git"
bench "git status" "git status" "$PRLTC git status"
bench "git log -n 10" "git log -10" "$PRLTC git log -n 10"
bench "git log -n 5" "git log -5" "$PRLTC git log -n 5"
bench "git diff" "git diff HEAD~1 2>/dev/null || echo ''" "$PRLTC git diff"

# ===================
# grep
# ===================
section "grep"
bench "grep fn" "grep -rn 'fn ' src/ || true" "$PRLTC grep 'fn ' src/"
bench "grep struct" "grep -rn 'struct ' src/ || true" "$PRLTC grep 'struct ' src/"
bench "grep -l 40" "grep -rn 'fn ' src/ || true" "$PRLTC grep 'fn ' src/ -l 40"
bench "grep --max 20" "grep -rn 'fn ' src/ | head -20 || true" "$PRLTC grep 'fn ' src/ --max 20"
bench "grep -c" "grep -ron 'fn ' src/ || true" "$PRLTC grep 'fn ' src/ -c"

# ===================
# json
# ===================
section "json"
cat > /tmp/prltc_bench.json << 'JSONEOF'
{
  "name": "prltc",
  "version": "0.2.1",
  "config": {
    "debug": false,
    "max_depth": 10,
    "filters": ["node_modules", "target", ".git"]
  },
  "dependencies": {
    "serde": "1.0",
    "clap": "4.0",
    "anyhow": "1.0"
  }
}
JSONEOF
bench "json" "cat /tmp/prltc_bench.json" "$PRLTC json /tmp/prltc_bench.json"
bench "json -d 2" "cat /tmp/prltc_bench.json" "$PRLTC json /tmp/prltc_bench.json -d 2"
rm -f /tmp/prltc_bench.json

# ===================
# deps
# ===================
section "deps"
bench "deps" "cat Cargo.toml" "$PRLTC deps"

# ===================
# env
# ===================
section "env"
bench "env" "env" "$PRLTC env"
bench "env -f PATH" "env | grep PATH" "$PRLTC env -f PATH"
bench "env --show-all" "env" "$PRLTC env --show-all"

# ===================
# err
# ===================
section "err"
bench "err cargo build" "cargo build 2>&1 || true" "$PRLTC err cargo build"

# ===================
# test
# ===================
section "test"
bench "test cargo test" "cargo test 2>&1 || true" "$PRLTC test cargo test"

# ===================
# log
# ===================
section "log"
LOG_FILE="/tmp/prltc_bench_sample.log"
cat > "$LOG_FILE" << 'LOGEOF'
2024-01-15 10:00:01 INFO  Application started
2024-01-15 10:00:02 INFO  Loading configuration
2024-01-15 10:00:03 ERROR Connection failed: timeout
2024-01-15 10:00:04 ERROR Connection failed: timeout
2024-01-15 10:00:05 ERROR Connection failed: timeout
2024-01-15 10:00:06 ERROR Connection failed: timeout
2024-01-15 10:00:07 ERROR Connection failed: timeout
2024-01-15 10:00:08 WARN  Retrying connection
2024-01-15 10:00:09 INFO  Connection established
2024-01-15 10:00:10 INFO  Processing request
2024-01-15 10:00:11 INFO  Processing request
2024-01-15 10:00:12 INFO  Processing request
2024-01-15 10:00:13 INFO  Request completed
LOGEOF
bench "log" "cat $LOG_FILE" "$PRLTC log $LOG_FILE"
rm -f "$LOG_FILE"

# ===================
# summary
# ===================
section "summary"
bench "summary cargo --help" "cargo --help" "$PRLTC summary cargo --help"
bench "summary rustc --help" "rustc --help 2>/dev/null || echo 'rustc not found'" "$PRLTC summary rustc --help"

# ===================
# Modern JavaScript Stack (skip si pas de package.json)
# ===================
if [ -f "package.json" ]; then
  section "modern JS stack"

  if command -v tsc &> /dev/null || [ -f "node_modules/.bin/tsc" ]; then
    bench "tsc" "tsc --noEmit 2>&1 || true" "$PRLTC tsc --noEmit"
  fi

  if command -v prettier &> /dev/null || [ -f "node_modules/.bin/prettier" ]; then
    bench "prettier --check" "prettier --check . 2>&1 || true" "$PRLTC prettier --check ."
  fi

  if command -v eslint &> /dev/null || [ -f "node_modules/.bin/eslint" ]; then
    bench "lint" "eslint . 2>&1 || true" "$PRLTC lint ."
  fi

  if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
    if command -v next &> /dev/null || [ -f "node_modules/.bin/next" ]; then
      bench "next build" "next build 2>&1 || true" "$PRLTC next build"
    fi
  fi

  if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
    if command -v playwright &> /dev/null || [ -f "node_modules/.bin/playwright" ]; then
      bench "playwright test" "playwright test 2>&1 || true" "$PRLTC playwright test"
    fi
  fi

  if [ -f "prisma/schema.prisma" ]; then
    if command -v prisma &> /dev/null || [ -f "node_modules/.bin/prisma" ]; then
      bench "prisma generate" "prisma generate 2>&1 || true" "$PRLTC prisma generate"
    fi
  fi

  if command -v vitest &> /dev/null || [ -f "node_modules/.bin/vitest" ]; then
    bench "vitest run" "vitest run --reporter=json 2>&1 || true" "$PRLTC vitest run"
  fi

  if command -v pnpm &> /dev/null; then
    bench "pnpm list" "pnpm list --depth 0 2>&1 || true" "$PRLTC pnpm list --depth 0"
    bench "pnpm outdated" "pnpm outdated 2>&1 || true" "$PRLTC pnpm outdated"
  fi
fi

# ===================
# gh (skip si pas dispo ou pas dans un repo)
# ===================
if command -v gh &> /dev/null && git rev-parse --git-dir &> /dev/null; then
  section "gh"
  bench "gh pr list" "gh pr list 2>&1 || true" "$PRLTC gh pr list"
  bench "gh run list" "gh run list 2>&1 || true" "$PRLTC gh run list"
fi

# ===================
# docker (skip si pas dispo)
# ===================
if command -v docker &> /dev/null; then
  section "docker"
  bench "docker ps" "docker ps 2>/dev/null || true" "$PRLTC docker ps"
  bench "docker images" "docker images 2>/dev/null || true" "$PRLTC docker images"
fi

# ===================
# kubectl (skip si pas dispo)
# ===================
if command -v kubectl &> /dev/null; then
  section "kubectl"
  bench "kubectl pods" "kubectl get pods 2>/dev/null || true" "$PRLTC kubectl pods"
  bench "kubectl services" "kubectl get services 2>/dev/null || true" "$PRLTC kubectl services"
fi

# ===================
# Python (skip si pas de projet Python)
# ===================
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  section "Python stack"

  if command -v ruff &> /dev/null; then
    bench "ruff check" "ruff check . 2>&1 || true" "$PRLTC ruff check ."
    bench "ruff format --check" "ruff format --check . 2>&1 || true" "$PRLTC ruff format --check ."
  fi

  if command -v pytest &> /dev/null; then
    bench "pytest" "pytest --tb=short -q 2>&1 || true" "$PRLTC pytest"
  fi

  if command -v pip &> /dev/null; then
    bench "pip list" "pip list 2>&1 || true" "$PRLTC pip list"
    bench "pip outdated" "pip list --outdated 2>&1 || true" "$PRLTC pip outdated"
  fi
fi

# ===================
# Go (skip si pas de go.mod)
# ===================
if [ -f "go.mod" ]; then
  section "Go stack"

  if command -v go &> /dev/null; then
    bench "go test" "go test ./... 2>&1 || true" "$PRLTC go test ./..."
    bench "go build" "go build ./... 2>&1 || true" "$PRLTC go build ./..."
    bench "go vet" "go vet ./... 2>&1 || true" "$PRLTC go vet ./..."
  fi

  if command -v golangci-lint &> /dev/null; then
    bench "golangci-lint" "golangci-lint run 2>&1 || true" "$PRLTC golangci-lint run"
  fi
fi

# ===================
# Résumé global
# ===================
echo ""
echo "═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════"

if [ "$TOTAL_TESTS" -gt 0 ]; then
  GOOD_PCT=$((GOOD_TESTS * 100 / TOTAL_TESTS))
  if [ "$TOTAL_UNIX" -gt 0 ]; then
    TOTAL_SAVED=$((TOTAL_UNIX - TOTAL_PRLTC))
    TOTAL_SAVE_PCT=$((TOTAL_SAVED * 100 / TOTAL_UNIX))
  else
    TOTAL_SAVED=0
    TOTAL_SAVE_PCT=0
  fi

  echo ""
  echo "  ✅ $GOOD_TESTS good  ⚠️ $SKIP_TESTS skip  ❌ $FAIL_TESTS fail    $GOOD_TESTS/$TOTAL_TESTS ($GOOD_PCT%)"
  echo "  Tokens: $TOTAL_UNIX → $TOTAL_PRLTC  (-$TOTAL_SAVE_PCT%)"
  echo ""

  # Fichiers debug en local
  if [ -z "$CI" ]; then
    echo "  Debug: $BENCH_DIR/{unix,prltc,diff}/"
  fi
  echo ""

  # Exit code non-zero si moins de 80% good
  if [ "$GOOD_PCT" -lt 80 ]; then
    echo "  BENCHMARK FAILED: $GOOD_PCT% good (minimum 80%)"
    exit 1
  fi
fi
