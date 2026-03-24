# PRLTC Installation Guide - For AI Coding Assistants

## Pre-Installation Check (REQUIRED)

**AI assistants should ALWAYS verify if PRLTC is already installed before attempting installation.**

```bash
# Check if PRLTC is installed
prltc --version

# Check installation path
which prltc
```

If PRLTC is already installed and working, **DO NOT reinstall**. Skip directly to "Project Initialization" section.

## Installation (only if PRLTC not available)

### Option 1: Install from fork (RECOMMENDED currently)

This fork includes critical fixes and pnpm/Vitest support not yet merged upstream.

```bash
# Clone the fork
git clone https://github.com/FlorianBruniaux/prltc.git
cd prltc

# Check branch (should be master or feat/vitest-support)
git branch

# Compile and install
cargo install --path . --force

# Verify installation
prltc --version
```

### Option 2: Install from upstream (when PRs are merged)

```bash
cargo install prltc
```

## Project Initialization

**For each project where you want to use PRLTC:**

```bash
# Navigate to project directory
cd /path/to/your/project

# Initialize PRLTC for this project (creates ./CLAUDE.md)
prltc init

# OR initialize globally (creates ~/CLAUDE.md for all projects)
prltc init --global
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

- **Issues**: https://github.com/pszymkowiak/prltc/issues (upstream)
- **Fork issues**: https://github.com/FlorianBruniaux/prltc/issues
- **Pull Requests**: Create on fork then propose upstream

## AI Assistant Checklist

Before each session:

- [ ] Verify PRLTC is installed: `prltc --version`
- [ ] If not installed → follow "Install from fork"
- [ ] If project not initialized → `prltc init`
- [ ] Use `prltc` for ALL git/pnpm/test/vitest commands
- [ ] Check savings: `prltc gain`

**Golden Rule**: AI coding assistants should ALWAYS use `prltc` as a proxy for shell commands that generate verbose output (git, pnpm, npm, cargo test, vitest, docker, kubectl).
