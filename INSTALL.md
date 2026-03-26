# PRLTC Installation Guide - For AI Coding Assistants

## ⚠️ Name Collision Warning

**There are TWO completely different projects named "prltc":**

1. ✅ **Rust Token Killer** (this project) - LLM token optimizer
   - Repos: `ekjotsinghmakhija/prltc`
   - Has `prltc gain` command for token savings stats

2. ❌ **Rust Type Kit** (reachingforthejack/prltc) - DIFFERENT PROJECT
   - Rust codebase query tool and type generator
   - **DO NOT install if you want token optimization**

## Pre-Installation Check (REQUIRED)

**AI assistants should ALWAYS verify if PRLTC is already installed before attempting installation.**

```bash
# Check if PRLTC is installed
prltc --version

# CRITICAL: Verify it's the Token Killer (not Type Kit)
prltc gain    # Should show token savings stats, NOT "command not found"

# Check installation path
which prltc
```

If `prltc gain` works, you have the **correct** PRLTC installed. **DO NOT reinstall**. Skip to "Project Initialization".

If `prltc gain` fails but `prltc --version` succeeds, you have the **wrong** PRLTC (Type Kit). Uninstall and reinstall the correct one (see below).

## Installation (only if PRLTC not available or wrong PRLTC installed)

### Step 0: Uninstall Wrong PRLTC (if needed)

If you accidentally installed Rust Type Kit:

```bash
cargo uninstall prltc
```

### Quick Install (Linux/macOS)

```bash
curl -fsSL https://github.com/ekjotsinghmakhija/prltc/blob/master/install.sh | sh
```

After installation, **verify you have the correct prltc**:
```bash
prltc gain  # Must show token savings stats (not "command not found")
```

### Alternative: Manual Installation

```bash
# From ekjotsinghmakhija repository (NOT reachingforthejack!)
cargo install --git https://github.com/ekjotsinghmakhija/prltc

# OR (if published and correct on crates.io)
cargo install prltc

# ALWAYS VERIFY after installation
prltc gain  # MUST show token savings, not "command not found"
```

⚠️ **WARNING**: `cargo install prltc` from crates.io might install the wrong package. Always verify with `prltc gain`.

## Project Initialization

### Recommended: Global Hook-First Setup

**Best for: All projects, automatic PRLTC usage**

```bash
prltc init -g
# → Installs hook to ~/.claude/hooks/prltc-rewrite.sh
# → Creates ~/.claude/PRLTC.md (10 lines, meta commands only)
# → Adds @PRLTC.md reference to ~/.claude/CLAUDE.md
# → Prompts: "Patch settings.json? [y/N]"
# → If yes: patches + creates backup (~/.claude/settings.json.bak)

# Automated alternatives:
prltc init -g --auto-patch    # Patch without prompting
prltc init -g --no-patch      # Print manual instructions instead

# Verify installation
prltc init --show  # Check hook is installed and executable
```

**Token savings**: ~99.5% reduction (2000 tokens → 10 tokens in context)

**What is settings.json?**
Claude Code's hook registry. PRLTC adds a PreToolUse hook that rewrites commands transparently. Without this, Claude won't invoke the hook automatically.

**Backup Safety**:
PRLTC backs up existing settings.json before changes. Restore if needed:
```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

### Alternative: Local Project Setup

**Best for: Single project without hook**

```bash
cd /path/to/your/project
prltc init  # Creates ./CLAUDE.md with full PRLTC instructions (137 lines)
```

**Token savings**: Instructions loaded only for this project

### Upgrading from Previous Version

If you previously used `prltc init -g` with the old system (137-line injection):

```bash
prltc init -g  # Automatically migrates to hook-first mode
# → Removes old 137-line block
# → Installs hook + PRLTC.md
# → Adds @PRLTC.md reference
```

## Common User Flows

### First-Time User (Recommended)
```bash
# 1. Install PRLTC
cargo install --git https://github.com/ekjotsinghmakhija/prltc
prltc gain  # Verify (must show token stats)

# 2. Setup with prompts
prltc init -g
# → Answer 'y' when prompted to patch settings.json
# → Creates backup automatically

# 3. Restart Claude Code
# 4. Test: git status (should use prltc)
```

### CI/CD or Automation
```bash
# Non-interactive setup (no prompts)
prltc init -g --auto-patch

# Verify in scripts
prltc init --show | grep "Hook:"
```

### Conservative User (Manual Control)
```bash
# Get manual instructions without patching
prltc init -g --no-patch

# Review printed JSON snippet
# Manually edit ~/.claude/settings.json
# Restart Claude Code
```

### Temporary Trial
```bash
# Install hook
prltc init -g --auto-patch

# Later: remove everything
prltc init -g --uninstall

# Restore backup if needed
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

## Installation Verification

```bash
# Basic test
prltc ls .

# Test with git
prltc git status

# Test with pnpm (fork only)
prltc pnpm list

# Test with Vitest (feat/vitest-support branch only)
prltc vitest run
```

## Uninstalling

### Complete Removal (Global Installations Only)

```bash
# Complete removal (global installations only)
prltc init -g --uninstall

# What gets removed:
#   - Hook: ~/.claude/hooks/prltc-rewrite.sh
#   - Context: ~/.claude/PRLTC.md
#   - Reference: @PRLTC.md line from ~/.claude/CLAUDE.md
#   - Registration: PRLTC hook entry from settings.json

# Restart Claude Code after uninstall
```

**For Local Projects**: Manually remove PRLTC block from `./CLAUDE.md`

### Binary Removal

```bash
# If installed via cargo
cargo uninstall prltc

# If installed via package manager
brew uninstall prltc          # macOS Homebrew
sudo apt remove prltc         # Debian/Ubuntu
sudo dnf remove prltc         # Fedora/RHEL
```

### Restore from Backup (if needed)

```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

## Essential Commands

### Files
```bash
prltc ls .              # Compact tree view
prltc read file.rs      # Optimized reading
prltc grep "pattern" .  # Grouped search results
```

### Git
```bash
prltc git status        # Compact status
prltc git log -n 10     # Condensed logs
prltc git diff          # Optimized diff
prltc git add .         # → "ok ✓"
prltc git commit -m "msg"  # → "ok ✓ abc1234"
prltc git push          # → "ok ✓ main"
```

### Pnpm (fork only)
```bash
prltc pnpm list         # Dependency tree (-70% tokens)
prltc pnpm outdated     # Available updates (-80-90%)
prltc pnpm install pkg  # Silent installation
```

### Tests
```bash
prltc test cargo test   # Failures only (-90%)
prltc vitest run        # Filtered Vitest output (-99.6%)
```

### Statistics
```bash
prltc gain              # Token savings
prltc gain --graph      # With ASCII graph
prltc gain --history    # With command history
```

## Validated Token Savings

### Production T3 Stack Project
| Operation | Standard | PRLTC | Reduction |
|-----------|----------|-----|-----------|
| `vitest run` | 102,199 chars | 377 chars | **-99.6%** |
| `git status` | 529 chars | 217 chars | **-59%** |
| `pnpm list` | ~8,000 tokens | ~2,400 | **-70%** |
| `pnpm outdated` | ~12,000 tokens | ~1,200-2,400 | **-80-90%** |

### Typical Claude Code Session (30 min)
- **Without PRLTC**: ~150,000 tokens
- **With PRLTC**: ~45,000 tokens
- **Savings**: **70% reduction**

## Troubleshooting

### PRLTC command not found after installation
```bash
# Check PATH
echo $PATH | grep -o '[^:]*\.cargo[^:]*'

# Add to PATH if needed (~/.bashrc or ~/.zshrc)
export PATH="$HOME/.cargo/bin:$PATH"

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

### PRLTC command not available (e.g., vitest)
```bash
# Check branch
cd /path/to/prltc
git branch

# Switch to feat/vitest-support if needed
git checkout feat/vitest-support

# Reinstall
cargo install --path . --force
```

### Compilation error
```bash
# Update Rust
rustup update stable

# Clean and recompile
cargo clean
cargo build --release
cargo install --path . --force
```

## Support and Contributing

- **Troubleshooting**: See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues
- **GitHub issues**: https://github.com/ekjotsinghmakhija/prltc/issues
- **Pull Requests**: https://github.com/ekjotsinghmakhija/prltc/pulls

⚠️ **If you installed the wrong prltc (Type Kit)**, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#problem-prltc-gain-command-not-found)

## AI Assistant Checklist

Before each session:

- [ ] Verify PRLTC is installed: `prltc --version`
- [ ] If not installed → follow "Install from fork"
- [ ] If project not initialized → `prltc init`
- [ ] Use `prltc` for ALL git/pnpm/test/vitest commands
- [ ] Check savings: `prltc gain`

**Golden Rule**: AI coding assistants should ALWAYS use `prltc` as a proxy for shell commands that generate verbose output (git, pnpm, npm, cargo test, vitest, docker, kubectl).
