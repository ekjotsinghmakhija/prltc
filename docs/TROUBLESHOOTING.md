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
curl -fsSL https://github.com/ekjotsinghmakhija/prltc/blob/master/install.sh | sh
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
| **Rust Token Killer** ✅ | ekjotsinghmakhija/prltc | LLM token optimizer for Claude Code | `prltc gain` |
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

**4. Install auto-rewrite hook (recommended for automatic PRLTC usage):**

**Option A: Automatic (recommended)**
```bash
prltc init -g
# → Installs hook + PRLTC.md automatically
# → Follow printed instructions to add hook to ~/.claude/settings.json
# → Restart Claude Code

# Verify installation
prltc init --show  # Should show "✅ Hook: executable, with guards"
```

**Option B: Manual (fallback)**
```bash
# Copy hook to Claude Code hooks directory
mkdir -p ~/.claude/hooks
cp .claude/hooks/prltc-rewrite.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/prltc-rewrite.sh
```

Then add to `~/.claude/settings.json` (replace `~` with full path):
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/yourname/.claude/hooks/prltc-rewrite.sh"
          }
        ]
      }
    ]
  }
}
```

**Note**: Use absolute path in `settings.json`, not `~/.claude/...`

---

## Problem: PRLTC not working in OpenCode

### Symptom
OpenCode runs commands without prltc, outputs are verbose.

### Checklist

**1. Verify prltc is installed and correct:**
```bash
prltc --version
prltc gain  # Must show stats
```

**2. Install the OpenCode plugin (global only):**
```bash
prltc init -g --opencode
```

**3. Verify plugin file exists:**
```bash
ls -la ~/.config/opencode/plugins/prltc.ts
```

**4. Restart OpenCode**
OpenCode must be restarted to load the plugin.

**5. Verify status:**
```bash
prltc init --show  # Should show "OpenCode: plugin installed"
```

---

## Problem: PRLTC commands fail on Windows ("program not found" or "No such file")

### Symptom
```
prltc vitest --run
# Error: program not found
# Or: The system cannot find the file specified

prltc lint .
# Error: No such file or directory
```

### Root Cause
On Windows, Node.js tools (vitest, eslint, tsc, etc.) are installed as `.CMD` or `.BAT` wrapper scripts, not as native `.exe` binaries. Rust's `std::process::Command::new("vitest")` does not honor the Windows `PATHEXT` environment variable, so it cannot find `vitest.CMD` even when it's on PATH.

### Solution
Update to prltc v0.23.1+ which resolves this via the `which` crate for proper PATH+PATHEXT resolution. All 16+ command modules now use `resolved_command()` instead of `Command::new()`.

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
prltc --version  # Should be 0.23.1+
```

### Affected Commands
All commands that spawn external tools: `prltc vitest`, `prltc lint`, `prltc tsc`, `prltc pnpm`, `prltc playwright`, `prltc prisma`, `prltc next`, `prltc prettier`, `prltc ruff`, `prltc pytest`, `prltc pip`, `prltc mypy`, `prltc golangci-lint`, and others.

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
