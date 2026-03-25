# PRLTC Troubleshooting Guide

## Problem: "prltc gain" command not found

### Symptom
```bash
$ prltc --version
prltc 1.0.0  # (or similar)

$ prltc gain
prltc: 'gain' is not a prltc command. See 'prltc --help'.
```

### Root Cause
You installed the **wrong prltc package**. You have **Rust Type Kit** (reachingforthejack/prltc) instead of **Rust Token Killer** (ekjotsinghmakhija/prltc).

### Solution

**1. Uninstall the wrong package:**
```bash
cargo uninstall prltc
```

**2. Install the correct one (Token Killer):**

#### Quick Install (Linux/macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/pszymkowiak/prltc/master/install.sh | sh
```

#### Alternative: Manual Installation
```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

**3. Verify installation:**
```bash
prltc --version
prltc gain  # MUST show token savings stats, not error
```

If `prltc gain` now works, installation is correct.

---

## Problem: Confusion Between Two "prltc" Projects

### The Two Projects

| Project | Repository | Purpose | Key Command |
|---------|-----------|---------|-------------|
| **Rust Token Killer** ✅ | ekjotsinghmakhija/prltc, pszymkowiak/prltc | LLM token optimizer for Claude Code | `prltc gain` |
| **Rust Type Kit** ❌ | reachingforthejack/prltc | Rust codebase query and type generator | `prltc query` |

### How to Identify Which One You Have

```bash
# Check if "gain" command exists
prltc gain

# Token Killer → Shows token savings stats
# Type Kit → Error: "gain is not a prltc command"
```

---

## Problem: cargo install prltc installs wrong package

### Why This Happens
If **Rust Type Kit** is published to crates.io under the name `prltc`, running `cargo install prltc` will install the wrong package.

### Solution
**NEVER use** `cargo install prltc` without verifying.

**Always use explicit repository URLs:**

```bash
# CORRECT - Token Killer
cargo install --git https://github.com/ekjotsinghmakhija/prltc

# OR install from fork
git clone https://github.com/ekjotsinghmakhija/prltc.git
cd prltc && git checkout feat/all-features
cargo install --path . --force
```

**After any installation, ALWAYS verify:**
```bash
prltc gain  # Must work if you want Token Killer
```

---

## Problem: PRLTC not working in Claude Code

### Symptom
Claude Code doesn't seem to be using prltc, outputs are verbose.

### Checklist

**1. Verify prltc is installed and correct:**
```bash
prltc --version
prltc gain  # Must show stats
```

**2. Initialize prltc for Claude Code:**
```bash
# Global (all projects)
prltc init --global

# Per-project
cd /your/project
prltc init
```

**3. Verify CLAUDE.md file exists:**
```bash
# Check global
cat ~/.claude/CLAUDE.md | grep prltc

# Check project
cat ./CLAUDE.md | grep prltc
```

**4. Optional: Install auto-rewrite hook (recommended):**
```bash
# Copy hook to Claude Code hooks directory
mkdir -p ~/.claude/hooks
cp .claude/hooks/prltc-rewrite.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/prltc-rewrite.sh
```

Then add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/prltc-rewrite.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Problem: "command not found: prltc" after installation

### Symptom
```bash
$ cargo install --path . --force
   Compiling prltc v0.7.1
    Finished release [optimized] target(s)
  Installing ~/.cargo/bin/prltc

$ prltc --version
zsh: command not found: prltc
```

### Root Cause
`~/.cargo/bin` is not in your PATH.

### Solution

**1. Check if cargo bin is in PATH:**
```bash
echo $PATH | grep -o '[^:]*\.cargo[^:]*'
```

**2. If not found, add to PATH:**

For **bash** (`~/.bashrc`):
```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

For **zsh** (`~/.zshrc`):
```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

For **fish** (`~/.config/fish/config.fish`):
```fish
set -gx PATH $HOME/.cargo/bin $PATH
```

**3. Reload shell config:**
```bash
source ~/.bashrc  # or ~/.zshrc or restart terminal
```

**4. Verify:**
```bash
which prltc
prltc --version
prltc gain
```

---

## Problem: Compilation errors during installation

### Symptom
```bash
$ cargo install --path .
error: failed to compile prltc v0.7.1
```

### Solutions

**1. Update Rust toolchain:**
```bash
rustup update stable
rustup default stable
```

**2. Clean and rebuild:**
```bash
cargo clean
cargo build --release
cargo install --path . --force
```

**3. Check Rust version (minimum required):**
```bash
rustc --version  # Should be 1.70+ for most features
```

**4. If still fails, report issue:**
- GitHub: https://github.com/ekjotsinghmakhija/prltc/issues

---

## Problem: Missing commands (vitest, pnpm, next, etc.)

### Symptom
```bash
$ prltc vitest run
error: 'vitest' is not a prltc command
```

### Root Cause
You installed the upstream version, which doesn't have all features yet.

### Solution
Install the **fork with all features**:

```bash
# Uninstall current version
cargo uninstall prltc

# Install fork
git clone https://github.com/ekjotsinghmakhija/prltc.git
cd prltc && git checkout feat/all-features
cargo install --path . --force

# Verify all commands available
prltc --help | grep vitest
prltc --help | grep pnpm
prltc --help | grep next
```

### Available Commands by Version

| Command | Upstream (ekjotsinghmakhija) | Fork (feat/all-features) |
|---------|-------------------|--------------------------|
| `prltc gain` | ✅ | ✅ |
| `prltc git` | ✅ | ✅ |
| `prltc gh` | ✅ | ✅ |
| `prltc pnpm` | ❌ | ✅ |
| `prltc vitest` | ❌ | ✅ |
| `prltc lint` | ❌ | ✅ |
| `prltc tsc` | ❌ | ✅ |
| `prltc next` | ❌ | ✅ |
| `prltc prettier` | ❌ | ✅ |
| `prltc playwright` | ❌ | ✅ |
| `prltc prisma` | ❌ | ✅ |
| `prltc discover` | ❌ | ✅ |

---

## Need More Help?

**Report issues:**
- Fork-specific: https://github.com/ekjotsinghmakhija/prltc/issues
- Upstream: https://github.com/ekjotsinghmakhija/prltc/issues

**Run the diagnostic script:**
```bash
# From the prltc repository root
bash scripts/check-installation.sh
```

This script will check:
- ✅ PRLTC installed and in PATH
- ✅ Correct version (Token Killer, not Type Kit)
- ✅ Available features (pnpm, vitest, next, etc.)
- ✅ Claude Code integration (CLAUDE.md files)
- ✅ Auto-rewrite hook status

The script provides specific fix commands for any issues found.
