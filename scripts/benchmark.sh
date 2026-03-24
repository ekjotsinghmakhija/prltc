#!/bin/bash
set -e

PRLTC="./target/release/prltc"
BENCH_DIR="scripts/benchmark"
REPORT="benchmark-report.md"

# Nettoyer et créer le dossier benchmark
rm -rf "$BENCH_DIR"
mkdir -p "$BENCH_DIR/unix"
mkdir -p "$BENCH_DIR/prltc"
mkdir -p "$BENCH_DIR/diff"

# Fonction pour compter les tokens (~4 chars = 1 token)
count_tokens() {
  local input="$1"
  local len=${#input}
  echo $(( (len + 3) / 4 ))
}

# Fonction pour créer un nom de fichier safe
safe_name() {
  echo "$1" | tr ' /' '_-' | tr -cd 'a-zA-Z0-9_-'
}

# Fonction de benchmark
bench() {
  local name="$1"
  local unix_cmd="$2"
  local prltc_cmd="$3"
  local filename=$(safe_name "$name")

  unix_out=$(eval "$unix_cmd" 2>/dev/null || true)
  prltc_out=$(eval "$prltc_cmd" 2>/dev/null || true)

  unix_tokens=$(count_tokens "$unix_out")
  prltc_tokens=$(count_tokens "$prltc_out")

  # Déterminer si PRLTC économise des tokens
  local use_prltc=true
  local status="✅"
  local prefix="GOOD"
  local recommended_cmd="$prltc_cmd"
  local recommended_out="$prltc_out"

  if [ "$prltc_tokens" -ge "$unix_tokens" ] && [ "$unix_tokens" -gt 0 ]; then
    use_prltc=false
    status="⚠️ SKIP"
    prefix="BAD"
    recommended_cmd="$unix_cmd"
    recommended_out="$unix_out"
  fi

  if [ "$unix_tokens" -gt 0 ]; then
    local diff_pct=$(( (unix_tokens - prltc_tokens) * 100 / unix_tokens ))
  else
    local diff_pct=0
  fi

  # Sauvegarder les outputs dans des fichiers md
  {
    echo "# Unix: $name"
    echo ""
    echo "\`\`\`bash"
    echo "$ $unix_cmd"
    echo "\`\`\`"
    echo ""
    echo "## Output"
    echo ""
    echo "\`\`\`"
    echo "$unix_out"
    echo "\`\`\`"
  } > "$BENCH_DIR/unix/${filename}.md"

  {
    echo "# PRLTC: $name"
    echo ""
    echo "\`\`\`bash"
    echo "$ $prltc_cmd"
    echo "\`\`\`"
    echo ""
    echo "## Output"
    echo ""
    echo "\`\`\`"
    echo "$prltc_out"
    echo "\`\`\`"
  } > "$BENCH_DIR/prltc/${filename}.md"

  # Générer le diff comparatif
  {
    echo "# Diff: $name"
    echo ""
    if [ "$use_prltc" = false ]; then
      echo "> ⚠️ **PRLTC adds tokens here!** Use Unix command instead."
      echo ""
    fi
    echo "| Metric | Unix | PRLTC | Saved | Status |"
    echo "|--------|------|-----|-------|--------|"
    echo "| Tokens | $unix_tokens | $prltc_tokens | $diff_pct% | $status |"
    echo "| Chars | ${#unix_out} | ${#prltc_out} | | |"
    echo ""
    echo "## Recommended Command"
    echo ""
    echo "\`\`\`bash"
    echo "$ $recommended_cmd"
    echo "\`\`\`"
    echo ""
    echo "## Commands"
    echo ""
    echo "\`\`\`bash"
    echo "# Unix"
    echo "$ $unix_cmd"
    echo ""
    echo "# PRLTC"
    echo "$ $prltc_cmd"
    echo "\`\`\`"
    echo ""
    echo "---"
    echo ""
    echo "## Unix Output"
    echo ""
    echo "\`\`\`"
    echo "$unix_out"
    echo "\`\`\`"
    echo ""
    echo "---"
    echo ""
    echo "## PRLTC Output"
    echo ""
    echo "\`\`\`"
    echo "$prltc_out"
    echo "\`\`\`"
    echo ""
    echo "---"
    echo ""
    echo "## Diff (Unix → PRLTC)"
    echo ""
    echo "\`\`\`diff"
    diff <(echo "$unix_out") <(echo "$prltc_out") || true
    echo "\`\`\`"
  } > "$BENCH_DIR/diff/${prefix}-${filename}.md"
  prltc_tokens=$(count_tokens "$prltc_out")

  if [ "$unix_tokens" -gt 0 ]; then
    saved=$((unix_tokens - prltc_tokens))
    pct=$((saved * 100 / unix_tokens))
  else
    saved=0
    pct=0
  fi

  # Accumuler pour le résumé (seulement si PRLTC économise)
  TOTAL_UNIX=$((TOTAL_UNIX + unix_tokens))
  if [ "$use_prltc" = true ]; then
    TOTAL_PRLTC=$((TOTAL_PRLTC + prltc_tokens))
  else
    TOTAL_PRLTC=$((TOTAL_PRLTC + unix_tokens))
    SKIPPED=$((SKIPPED + 1))
  fi

  echo "| $name | $unix_tokens | $prltc_tokens | $diff_pct% | $status |" >> "$REPORT"

  # Ajouter aux recommandations
  echo "| $name | \`$recommended_cmd\` |" >> "$RECOMMEND"
}

# Init totaux
TOTAL_UNIX=0
TOTAL_PRLTC=0
SKIPPED=0
RECOMMEND="$BENCH_DIR/recommendations.md"

# Header rapport
echo "# PRLTC Benchmark Report" > "$REPORT"
echo "" >> "$REPORT"
echo "| Command | Unix tokens | PRLTC tokens | Saved | Status |" >> "$REPORT"
echo "|---------|-------------|------------|-------|--------|" >> "$REPORT"

# Header recommandations
echo "# PRLTC Recommended Commands" > "$RECOMMEND"
echo "" >> "$RECOMMEND"
echo "Use these commands for optimal token savings:" >> "$RECOMMEND"
echo "" >> "$RECOMMEND"
echo "| Command | Recommended |" >> "$RECOMMEND"
echo "|---------|-------------|" >> "$RECOMMEND"

# ===================
# ls
# ===================
echo "" >> "$REPORT"
echo "| **ls** | | | |" >> "$REPORT"
bench "ls" "ls -la" "$PRLTC ls"
bench "ls src/" "ls -la src/" "$PRLTC ls src/"
bench "ls -a" "ls -la" "$PRLTC ls -a"
bench "ls -d 3" "find . -maxdepth 3 -type f" "$PRLTC ls -d 3"
bench "ls -d 3 -f tree" "tree -L 3 2>/dev/null || find . -maxdepth 3" "$PRLTC ls -d 3 -f tree"
bench "ls -f json" "ls -la" "$PRLTC ls -f json"
bench "ls -a -d 2 -f tree" "tree -L 2 -a 2>/dev/null || find . -maxdepth 2" "$PRLTC ls -a -d 2 -f tree"

# ===================
# read
# ===================
echo "" >> "$REPORT"
echo "| **read** | | | |" >> "$REPORT"
bench "read" "cat src/main.rs" "$PRLTC read src/main.rs"
bench "read -l minimal" "cat src/main.rs" "$PRLTC read src/main.rs -l minimal"
bench "read -l aggressive" "cat src/main.rs" "$PRLTC read src/main.rs -l aggressive"
bench "read -n" "cat -n src/main.rs" "$PRLTC read src/main.rs -n"


# ===================
# find
# ===================
echo "" >> "$REPORT"
echo "| **find** | | | |" >> "$REPORT"
bench "find *" "find . -type f" "$PRLTC find '*'"
bench "find *.rs" "find . -name '*.rs' -type f" "$PRLTC find '*.rs'"
bench "find *.toml" "find . -name '*.toml' -type f" "$PRLTC find '*.toml'"
bench "find --max 10" "find . -type f | head -10" "$PRLTC find '*' --max 10"
bench "find --max 100" "find . -type f | head -100" "$PRLTC find '*' --max 100"

# ===================
# diff
# ===================
echo "" >> "$REPORT"
echo "| **diff** | | | |" >> "$REPORT"
# Créer fichiers temp pour test diff
echo -e "line1\nline2\nline3" > /tmp/prltc_bench_f1.txt
echo -e "line1\nmodified\nline3\nline4" > /tmp/prltc_bench_f2.txt
bench "diff" "diff /tmp/prltc_bench_f1.txt /tmp/prltc_bench_f2.txt || true" "$PRLTC diff /tmp/prltc_bench_f1.txt /tmp/prltc_bench_f2.txt"
rm -f /tmp/prltc_bench_f1.txt /tmp/prltc_bench_f2.txt

# ===================
# git
# ===================
echo "" >> "$REPORT"
echo "| **git** | | | |" >> "$REPORT"
bench "git status" "git status" "$PRLTC git status"
bench "git log -n 10" "git log -10 --oneline" "$PRLTC git log -n 10"
bench "git log -n 5" "git log -5" "$PRLTC git log -n 5"
bench "git diff" "git diff HEAD~1 2>/dev/null || echo ''" "$PRLTC git diff"

# ===================
# grep
# ===================
echo "" >> "$REPORT"
echo "| **grep** | | | |" >> "$REPORT"
bench "grep fn" "grep -rn 'fn ' src/ || true" "$PRLTC grep 'fn ' src/"
bench "grep struct" "grep -rn 'struct ' src/ || true" "$PRLTC grep 'struct ' src/"
bench "grep -l 40" "grep -rn 'fn ' src/ || true" "$PRLTC grep 'fn ' src/ -l 40"
bench "grep --max 20" "grep -rn 'fn ' src/ | head -20 || true" "$PRLTC grep 'fn ' src/ --max 20"
bench "grep -c" "grep -ron 'fn ' src/ || true" "$PRLTC grep 'fn ' src/ -c"

# ===================
# json
# ===================
echo "" >> "$REPORT"
echo "| **json** | | | |" >> "$REPORT"
# Créer un fichier JSON de test
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
echo "" >> "$REPORT"
echo "| **deps** | | | |" >> "$REPORT"
bench "deps" "cat Cargo.toml" "$PRLTC deps"

# ===================
# env
# ===================
echo "" >> "$REPORT"
echo "| **env** | | | |" >> "$REPORT"
bench "env" "env" "$PRLTC env"
bench "env -f PATH" "env | grep PATH" "$PRLTC env -f PATH"
bench "env --show-all" "env" "$PRLTC env --show-all"

# ===================
# err
# ===================
echo "" >> "$REPORT"
echo "| **err** | | | |" >> "$REPORT"
bench "err echo test" "echo test 2>&1" "$PRLTC err echo test"

# ===================
# test
# ===================
echo "" >> "$REPORT"
echo "| **test** | | | |" >> "$REPORT"
bench "test cargo test" "cargo test 2>&1 || true" "$PRLTC test cargo test"

# ===================
# log
# ===================
echo "" >> "$REPORT"
echo "| **log** | | | |" >> "$REPORT"
# Créer un fichier log de test avec lignes répétées (pour montrer la déduplication)
LOG_FILE="$BENCH_DIR/sample.log"
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

# ===================
# summary
# ===================
echo "" >> "$REPORT"
echo "| **summary** | | | |" >> "$REPORT"
bench "summary cargo --help" "cargo --help" "$PRLTC summary cargo --help"
bench "summary rustc --help" "rustc --help 2>/dev/null || echo 'rustc not found'" "$PRLTC summary rustc --help"

# ===================
# docker (skip si pas dispo)
# ===================
if command -v docker &> /dev/null; then
  echo "" >> "$REPORT"
  echo "| **docker** | | | |" >> "$REPORT"
  bench "docker ps" "docker ps 2>/dev/null || true" "$PRLTC docker ps"
  bench "docker images" "docker images 2>/dev/null || true" "$PRLTC docker images"
fi

# ===================
# kubectl (skip si pas dispo)
# ===================
if command -v kubectl &> /dev/null; then
  echo "" >> "$REPORT"
  echo "| **kubectl** | | | |" >> "$REPORT"
  bench "kubectl pods" "kubectl get pods 2>/dev/null || true" "$PRLTC kubectl pods"
  bench "kubectl services" "kubectl get services 2>/dev/null || true" "$PRLTC kubectl services"
fi

# ===================
# Résumé global
# ===================
echo "" >> "$REPORT"
echo "## Summary" >> "$REPORT"
echo "" >> "$REPORT"

if [ "$TOTAL_UNIX" -gt 0 ]; then
  TOTAL_SAVED=$((TOTAL_UNIX - TOTAL_PRLTC))
  TOTAL_PCT=$((TOTAL_SAVED * 100 / TOTAL_UNIX))
  echo "| Metric | Value |" >> "$REPORT"
  echo "|--------|-------|" >> "$REPORT"
  echo "| Total Unix tokens | $TOTAL_UNIX |" >> "$REPORT"
  echo "| Total PRLTC tokens | $TOTAL_PRLTC |" >> "$REPORT"
  echo "| Total saved | $TOTAL_SAVED |" >> "$REPORT"
  echo "| **Global savings** | **$TOTAL_PCT%** |" >> "$REPORT"
  echo "| Commands skipped (no gain) | $SKIPPED |" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "Generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$REPORT"

echo ""
echo "=== BENCHMARK REPORT ==="
cat "$REPORT"

echo ""
echo "=== FILES GENERATED ==="
echo "Unix outputs: $BENCH_DIR/unix/"
echo "PRLTC outputs:  $BENCH_DIR/prltc/"
echo "Diff files:   $BENCH_DIR/diff/"
ls -1 "$BENCH_DIR/diff/" | wc -l | xargs echo "Total files:"
