# prltc - Rust Token Killer



**High-performance CLI proxy to minimize LLM token consumption.**

prltc filters and compresses command outputs before they reach your LLM context, saving 60-90% of tokens on common operations.

## Token Savings (30-min Claude Code Session)

Typical session without prltc: **~150,000 tokens**
With prltc: **~45,000 tokens** → **70% reduction**

| Operation | Frequency | Standard | prltc | Savings |
|-----------|-----------|----------|-----|---------|
| `ls` / `tree` | 10× | 2,000 | 400 | -80% |
| `cat` / `read` | 20× | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8× | 16,000 | 3,200 | -80% |
| `git status` | 10× | 3,000 | 600 | -80% |
| `git diff` | 5× | 10,000 | 2,500 | -75% |
| `git log` | 5× | 2,500 | 500 | -80% |
| `git add/commit/push` | 8× | 1,600 | 120 | -92% |
| `npm test` / `cargo test` | 5× | 25,000 | 2,500 | -90% |
| `docker ps` | 3× | 900 | 180 | -80% |
| **Total** | | **~101,000** | **~22,000** | **-78%** |

> Estimates based on medium-sized TypeScript/Rust projects. Actual savings vary by project size.

## Installation

### Quick Install (Linux/macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/pszymkowiak/prltc/master/install.sh | sh
```

### Homebrew (macOS) - Coming Soon
<!--
```bash
brew tap pszymkowiak/prltc
brew install prltc
```
-->

### Cargo
```bash
cargo install prltc
```

### Debian/Ubuntu
```bash
curl -LO https://github.com/pszymkowiak/prltc/releases/latest/download/prltc_0.2.1-1_amd64.deb
sudo dpkg -i prltc_0.2.1-1_amd64.deb
```

### Fedora/RHEL
```bash
curl -LO https://github.com/pszymkowiak/prltc/releases/latest/download/prltc-0.2.1-1.x86_64.rpm
sudo rpm -i prltc-0.2.1-1.x86_64.rpm
```

### Manual Download
Download binaries from [Releases](https://github.com/pszymkowiak/prltc/releases):
- macOS: `prltc-x86_64-apple-darwin.tar.gz` / `prltc-aarch64-apple-darwin.tar.gz`
- Linux: `prltc-x86_64-unknown-linux-gnu.tar.gz` / `prltc-aarch64-unknown-linux-gnu.tar.gz`
- Windows: `prltc-x86_64-pc-windows-msvc.zip`

## Quick Start

```bash
# Initialize prltc for Claude Code
prltc init --global    # Add to ~/CLAUDE.md (all projects)
prltc init             # Add to ./CLAUDE.md (this project)
```

## Commands

### Files
```bash
prltc ls .                        # Token-optimized directory tree
prltc read file.rs                # Smart file reading
prltc read file.rs -l aggressive  # Signatures only (strips bodies)
prltc find "*.rs" .               # Compact find results
prltc diff file1 file2            # Ultra-condensed diff
prltc grep "pattern" .            # Grouped search results
```

### Git
```bash
prltc git status                  # Compact status
prltc git log -n 10               # One-line commits
prltc git diff                    # Condensed diff
prltc git add                     # → "ok ✓"
prltc git commit -m "msg"         # → "ok ✓ abc1234"
prltc git push                    # → "ok ✓ main"
prltc git pull                    # → "ok ✓ 3 files +10 -2"
```

### Commands
```bash
prltc test cargo test             # Show failures only (-90% tokens)
prltc err npm run build           # Errors/warnings only
prltc summary <long command>      # Heuristic summary
prltc log app.log                 # Deduplicated logs
```

### Data
```bash
prltc json config.json            # Structure without values
prltc deps                        # Dependencies summary
prltc env -f AWS                  # Filtered env vars
prltc gain                        # Token savings stats
prltc gain --graph                # With ASCII graph
prltc gain --history              # With command history
```

### Containers
```bash
prltc docker ps                   # Compact container list
prltc docker images               # Compact image list
prltc docker logs <container>     # Deduplicated logs
prltc kubectl pods                # Compact pod list
prltc kubectl logs <pod>          # Deduplicated logs
```

## Examples

### Standard vs prltc

**Directory listing:**
```
# ls -la (45 lines, ~800 tokens)
drwxr-xr-x  15 user  staff    480 Jan 23 10:00 .
drwxr-xr-x   5 user  staff    160 Jan 23 09:00 ..
-rw-r--r--   1 user  staff   1234 Jan 23 10:00 Cargo.toml
...

# prltc ls (12 lines, ~150 tokens)
📁 my-project/
├── src/ (8 files)
│   ├── main.rs
│   └── lib.rs
├── Cargo.toml
└── README.md
```

**Git operations:**
```
# git push (15 lines, ~200 tokens)
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
...

# prltc git push (1 line, ~10 tokens)
ok ✓ main
```

**Test output:**
```
# cargo test (200+ lines on failure)
running 15 tests
test utils::test_parse ... ok
test utils::test_format ... ok
...

# prltc test cargo test (only failures, ~20 lines)
FAILED: 2/15 tests
  ✗ test_edge_case: assertion failed at src/lib.rs:42
  ✗ test_overflow: panic at src/utils.rs:18
```

## How It Works

1. **Smart Filtering**: Removes noise (comments, whitespace, boilerplate)
2. **Grouping**: Aggregates similar items (files by directory, errors by type)
3. **Truncation**: Keeps relevant context, cuts redundancy
4. **Deduplication**: Collapses repeated log lines with counts

## Improvements in This Fork

This fork adds critical fixes and modern JavaScript stack support to PRLTC, validated on production T3 Stack codebases.

### 🔧 PR #5: Git Argument Parsing Fix (CRITICAL)

**Status**: [Open](https://github.com/pszymkowiak/prltc/pull/5) | **Priority**: Critical

Fixes a major bug where git flags were rejected as invalid arguments.

**Problem**:
```bash
prltc git log --oneline -20
# Error: unexpected argument '--oneline' found
```

**Solution**:
- Fixed Clap argument parsing with `trailing_var_arg + allow_hyphen_values`
- Auto-detects `--merges` flag to skip `--no-merges` injection
- Propagates git exit codes properly (fixes CI/CD false positives)

**Now Working**:
```bash
prltc git log --oneline -20           # Compact commit history
prltc git diff --cached               # Staged changes only
prltc git log --graph --all           # Branch visualization
prltc git status --short              # Ultra-compact status
```

**Impact**: All git flags now work correctly, preventing workflow disruptions.

### 📦 PR #6: pnpm Support for Modern JavaScript Stacks

**Status**: [Open](https://github.com/pszymkowiak/prltc/pull/6) | **Target**: T3 Stack users

Adds first-class pnpm support with security hardening.

**New Commands**:
```bash
prltc pnpm list              # Dependency tree (70% token reduction)
prltc pnpm outdated          # Update candidates (80-90% reduction)
prltc pnpm install <pkg>     # Silent success confirmation
```

**Token Savings**:
| Command | Standard Output | prltc Output | Reduction |
|---------|----------------|------------|-----------|
| `pnpm list` | ~8,000 tokens | ~2,400 | -70% |
| `pnpm outdated` | ~12,000 tokens | ~1,200-2,400 | -80-90% |
| `pnpm install` | ~500 tokens | ~10 | -98% |

**Security**:
- Package name validation (prevents command injection)
- Proper error propagation (fixes CI/CD reliability)
- Comprehensive test coverage

### 🐛 Related Upstream Issues

This fork addresses issues reported upstream:
- [Issue #2](https://github.com/pszymkowiak/prltc/issues/2): Git argument parsing bug
- [Issue #3](https://github.com/pszymkowiak/prltc/issues/3): T3 Stack support request (pnpm + Vitest)
- [Issue #4](https://github.com/pszymkowiak/prltc/issues/4): grep/ls filtering improvements

### 🧪 Testing

**Production Validation**: All improvements tested on a production T3 Stack codebase:
- Framework: Next.js 15.1.5 + TypeScript
- Package Manager: pnpm 10.0.0
- Test Runner: Vitest
- Repository: 50+ files, 10,000+ lines of code

**Test Coverage**:
- Unit tests for all new commands
- Integration tests with real pnpm/git outputs
- Security validation for command injection prevention
- CI/CD pipeline validation (exit code propagation)

### 📥 Installation

**Use This Fork** (recommended until PRs are merged):
```bash
# Clone and build
git clone https://github.com/FlorianBruniaux/prltc.git
cd prltc
cargo build --release

# Install globally
cargo install --path .

# Or use directly
./target/release/prltc --version
```

**Track Upstream Merge Status**:
- Watch [PR #5](https://github.com/pszymkowiak/prltc/pull/5) for git fixes
- Watch [PR #6](https://github.com/pszymkowiak/prltc/pull/6) for pnpm support

**Switch to Upstream** (once merged):
```bash
cargo install prltc --force
```

## Configuration

prltc reads from `CLAUDE.md` files to instruct Claude Code to use prltc automatically:

```bash
prltc init --show    # Show current configuration
prltc init           # Create local CLAUDE.md
prltc init --global  # Create ~/CLAUDE.md
```

example of 3 days session:
```bash
📊 PRLTC Token Savings
════════════════════════════════════════

Total commands:    133
Input tokens:      30.5K
Output tokens:     10.7K
Tokens saved:      25.3K (83.0%)

By Command:
────────────────────────────────────────
Command               Count      Saved     Avg%
prltc git status           41      17.4K    82.9%
prltc git push             54       3.4K    91.6%
prltc grep                 15       3.2K    26.5%
prltc ls                   23       1.4K    37.2%

Daily Savings (last 30 days):
────────────────────────────────────────
01-23 │███████████████████                      6.4K
01-24 │██████████████████                       5.9K
01-25 │                                         18
01-26 │████████████████████████████████████████ 13.0K
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please open an issue or PR on GitHub.
