---
model: haiku
description: PRLTC environment diagnostics - Checks installation, hooks, version, command routing
---

# /diagnose

Vérifie l'état de l'environnement PRLTC et suggère des corrections.

## Quand utiliser

- **Automatiquement suggéré** quand Claude détecte ces patterns d'erreur :
  - `prltc: command not found` → PRLTC non installé ou pas dans PATH
  - Hook errors in Claude Code → Hooks mal configurés ou non exécutables
  - `Unknown command` dans PRLTC → Version incompatible ou commande non supportée
  - Token savings reports missing → `prltc gain` not working
  - Command routing errors → Hook integration broken

- **Manuellement** après installation, mise à jour PRLTC, ou si comportement suspect

## Exécution

### 1. Vérifications parallèles

Lancer ces commandes en parallèle :

```bash
# PRLTC installation check
which prltc && prltc --version || echo "❌ PRLTC not found in PATH"
```

```bash
# Git status (verify working directory)
git status --short && git branch --show-current
```

```bash
# Hook configuration check
if [ -f ".claude/hooks/prltc-rewrite.sh" ]; then
    echo "✅ OK: prltc-rewrite.sh hook present"
    # Check if hook is executable
    if [ -x ".claude/hooks/prltc-rewrite.sh" ]; then
        echo "✅ OK: hook is executable"
    else
        echo "⚠️ WARNING: hook not executable (chmod +x needed)"
    fi
else
    echo "❌ MISSING: prltc-rewrite.sh hook"
fi
```

```bash
# Hook prltc-suggest.sh check
if [ -f ".claude/hooks/prltc-suggest.sh" ]; then
    echo "✅ OK: prltc-suggest.sh hook present"
    if [ -x ".claude/hooks/prltc-suggest.sh" ]; then
        echo "✅ OK: hook is executable"
    else
        echo "⚠️ WARNING: hook not executable (chmod +x needed)"
    fi
else
    echo "❌ MISSING: prltc-suggest.sh hook"
fi
```

```bash
# Claude Code context check
if [ -n "$CLAUDE_CODE_HOOK_BASH_TEMPLATE" ]; then
    echo "✅ OK: Running in Claude Code context"
    echo "   Hook env var set: CLAUDE_CODE_HOOK_BASH_TEMPLATE"
else
    echo "⚠️ WARNING: Not running in Claude Code (hooks won't activate)"
    echo "   CLAUDE_CODE_HOOK_BASH_TEMPLATE not set"
fi
```

```bash
# Test command routing (dry-run)
if command -v prltc >/dev/null 2>&1; then
    # Test if prltc gain works (validates install)
    if prltc --help | grep -q "gain"; then
        echo "✅ OK: prltc gain available"
    else
        echo "❌ MISSING: prltc gain command (old version or wrong binary)"
    fi
else
    echo "❌ PRLTC binary not found"
fi
```

### 2. Validate token analytics

```bash
# Run prltc gain to verify analytics work
if command -v prltc >/dev/null 2>&1; then
    echo ""
    echo "📊 Token Savings (last 5 commands):"
    prltc gain --history 2>&1 | head -8 || echo "⚠️ prltc gain failed"
else
    echo "⚠️ Cannot test prltc gain (binary not installed)"
fi
```

### 3. Quality checks (if in PRLTC repo)

```bash
# Only run if we're in PRLTC repository
if [ -f "Cargo.toml" ] && grep -q 'name = "prltc"' Cargo.toml 2>/dev/null; then
    echo ""
    echo "🦀 PRLTC Repository Quality Checks:"

    # Check if cargo fmt passes
    if cargo fmt --all --check >/dev/null 2>&1; then
        echo "✅ OK: cargo fmt (code formatted)"
    else
        echo "⚠️ WARNING: cargo fmt needed"
    fi

    # Check if cargo clippy would pass (don't run full check, just verify binary)
    if command -v cargo-clippy >/dev/null 2>&1 || cargo clippy --version >/dev/null 2>&1; then
        echo "✅ OK: cargo clippy available"
    else
        echo "⚠️ WARNING: cargo clippy not installed"
    fi
else
    echo "ℹ️ Not in PRLTC repository (skipping quality checks)"
fi
```

## Format de sortie

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 PRLTC Environment Diagnostic
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 PRLTC Binary:      ✅ OK (v0.16.0) | ❌ NOT FOUND
🔗 Hooks:           ✅ OK (prltc-rewrite.sh + prltc-suggest.sh executable)
                    ❌ MISSING or ⚠️ WARNING (not executable)
📊 Token Analytics: ✅ OK (prltc gain working)
                    ❌ FAILED (command not available)
🎯 Claude Context:  ✅ OK (hook environment detected)
                    ⚠️ WARNING (not in Claude Code)
🦀 Code Quality:    ✅ OK (fmt + clippy ready) [if in PRLTC repo]
                    ⚠️ WARNING (needs formatting/clippy)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Actions suggérées

Utiliser `AskUserQuestion` si problèmes détectés :

```
question: "Problèmes détectés. Quelles corrections appliquer ?"
header: "Fixes"
multiSelect: true
options:
  - label: "cargo install --path ."
    description: "Installer PRLTC localement depuis le repo"
  - label: "chmod +x .claude/hooks/bash/*.sh"
    description: "Rendre les hooks exécutables"
  - label: "Tout corriger (recommandé)"
    description: "Install PRLTC + fix hooks permissions"
```

**Adaptations selon contexte** :

### Si PRLTC non installé
```
options:
  - label: "cargo install --path ."
    description: "Installer PRLTC localement (si dans le repo)"
  - label: "cargo install prltc"
    description: "Installer PRLTC depuis crates.io (dernière release)"
  - label: "brew install ekjotsinghmakhija/tap/prltc"
    description: "Installer PRLTC via Homebrew (macOS/Linux)"
```

### Si hooks manquants/non exécutables
```
options:
  - label: "chmod +x .claude/hooks/*.sh"
    description: "Rendre tous les hooks exécutables"
  - label: "Copier hooks depuis template"
    description: "Si hooks manquants, copier depuis repository principal"
```

### Si prltc gain échoue
```
options:
  - label: "Réinstaller PRLTC"
    description: "cargo install --path . --force (version outdated?)"
  - label: "Vérifier version"
    description: "prltc --version (besoin v0.16.0+ pour prltc gain)"
```

## Exécution des fixes

### Fix 1 : Installer PRLTC localement
```bash
cd /Users/florianbruniaux/Sites/ekjotsinghmakhija/prltc
cargo install --path .
# Vérifier installation
which prltc && prltc --version
```

### Fix 2 : Rendre hooks exécutables
```bash
chmod +x .claude/hooks/*.sh
# Vérifier permissions
ls -la .claude/hooks/*.sh
```

### Fix 3 : Tout corriger (recommandé)
```bash
# Install PRLTC
cargo install --path .

# Fix hooks permissions
chmod +x .claude/hooks/*.sh

# Verify
which prltc && prltc --version && prltc gain --history | head -3
```

## Détection automatique

**IMPORTANT** : Claude doit suggérer `/diagnose` automatiquement quand il voit :

| Erreur | Pattern | Cause probable |
|--------|---------|----------------|
| PRLTC not found | `prltc: command not found` | Pas installé ou pas dans PATH |
| Hook error | Hook execution failed, permission denied | Hooks non exécutables (`chmod +x` needed) |
| Version mismatch | `Unknown command` in PRLTC output | Version PRLTC incompatible (upgrade needed) |
| No analytics | `prltc gain` fails or command not found | PRLTC install incomplete or old version |
| Command not rewritten | Commands not proxied via PRLTC | Hook integration broken (check `CLAUDE_CODE_HOOK_BASH_TEMPLATE`) |

### Exemples de suggestion automatique

**Cas 1 : PRLTC command not found**
```
Cette erreur "prltc: command not found" indique que PRLTC n'est pas installé
ou pas dans le PATH. Je suggère de lancer `/diagnose` pour vérifier
l'installation et obtenir les commandes de fix.
```

**Cas 2 : Hook permission denied**
```
L'erreur "Permission denied" sur le hook prltc-rewrite.sh indique que
les hooks ne sont pas exécutables. Lance `/diagnose` pour identifier
le problème et corriger les permissions avec `chmod +x`.
```

**Cas 3 : prltc gain unavailable**
```
La commande `prltc gain` échoue, ce qui suggère une version PRLTC obsolète
ou une installation incomplète. `/diagnose` va vérifier la version et
suggérer une réinstallation si nécessaire.
```

## Troubleshooting Common Issues

### Issue : PRLTC installed but not in PATH

**Symptom**: `cargo install --path .` succeeds but `which prltc` fails

**Diagnosis**:
```bash
# Check if binary installed in Cargo bin
ls -la ~/.cargo/bin/prltc

# Check if ~/.cargo/bin in PATH
echo $PATH | grep -q .cargo/bin && echo "✅ In PATH" || echo "❌ Not in PATH"
```

**Fix**:
```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/.cargo/bin:$PATH"

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### Issue : Multiple PRLTC binaries (name collision)

**Symptom**: `prltc gain` fails with "command not found" even though `prltc --version` works

**Diagnosis**:
```bash
# Check if wrong PRLTC installed (reachingforthejack/prltc)
prltc --version
# Should show "prltc X.Y.Z", NOT "Rust Type Kit"

prltc --help | grep gain
# Should show "gain" command - if missing, wrong binary
```

**Fix**:
```bash
# Uninstall wrong PRLTC
cargo uninstall prltc

# Install correct PRLTC (this repo)
cargo install --path .

# Verify
prltc gain --help  # Should work
```

### Issue : Hooks not triggering in Claude Code

**Symptom**: Commands not rewritten to `prltc <cmd>` automatically

**Diagnosis**:
```bash
# Check if in Claude Code context
echo $CLAUDE_CODE_HOOK_BASH_TEMPLATE
# Should print hook template path - if empty, not in Claude Code

# Check hooks exist and executable
ls -la .claude/hooks/*.sh
# Should show -rwxr-xr-x (executable)
```

**Fix**:
```bash
# Make hooks executable
chmod +x .claude/hooks/*.sh

# Verify hooks load in new Claude Code session
# (restart Claude Code session after chmod)
```

## Version Compatibility Matrix

| PRLTC Version | prltc gain | prltc discover | Python/Go support | Notes |
|-------------|----------|--------------|-------------------|-------|
| v0.14.x     | ❌ No    | ❌ No        | ❌ No             | Outdated, upgrade |
| v0.15.x     | ✅ Yes   | ❌ No        | ❌ No             | Missing discover |
| v0.16.x     | ✅ Yes   | ✅ Yes       | ✅ Yes            | **Recommended** |
| main branch | ✅ Yes   | ✅ Yes       | ✅ Yes            | Latest features |

**Upgrade recommendation**: If running v0.15.x or older, upgrade to v0.16.x:

```bash
cd /Users/florianbruniaux/Sites/ekjotsinghmakhija/prltc
git pull origin main
cargo install --path . --force
prltc --version  # Should show 0.16.x or newer
```
