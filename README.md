# prltc - Rust Token Killer



**High-performance CLI proxy to minimize LLM token consumption.**

[Website](https://www.github.com/ekjotsinghmakhija/prltc) | [GitHub](https://github.com/ekjotsinghmakhija/prltc) | [Install](INSTALL.md)

prltc filters and compresses command outputs before they reach your LLM context, saving 60-90% of tokens on common operations.

## ⚠️ Important: Name Collision Warning

**There are TWO different projects named "prltc":**

1. ✅ **This project (Rust Token Killer)** - LLM token optimizer
   - Repos: `ekjotsinghmakhija/prltc`
   - Purpose: Reduce Claude Code token consumption

2. ❌ **reachingforthejack/prltc** - Rust Type Kit (DIFFERENT PROJECT)
   - Purpose: Query Rust codebase and generate types
   - **DO NOT install this one if you want token optimization**

**How to verify you have the correct prltc:**
```bash
prltc --version   # Should show "prltc 0.18.0"
prltc gain        # Should show token savings stats
```

If `prltc gain` doesn't exist, you installed the wrong package. See installation instructions below.

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
| `ruff check` | 3× | 3,000 | 600 | -80% |
| `pytest` | 4× | 8,000 | 800 | -90% |
| `go test` | 3× | 6,000 | 600 | -90% |
| `docker ps` | 3× | 900 | 180 | -80% |
| **Total** | | **~118,000** | **~23,900** | **-80%** |

> Estimates based on medium-sized TypeScript/Rust projects. Actual savings vary by project size.

## Installation

### ⚠️ Pre-Installation Check (REQUIRED)

**ALWAYS verify if prltc is already installed before installing:**

```bash
prltc --version        # Check if installed
prltc gain             # Verify it's the Token Killer (not Type Kit)
which prltc            # Check installation path
```

If already installed and `prltc gain` works, **DO NOT reinstall**. Skip to Quick Start.

### Quick Install (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

After installation, **verify you have the correct prltc**:
```bash
prltc gain  # Must show token savings stats (not "command not found")
```

### Alternative: Manual Installation

```bash
# From ekjotsinghmakhija upstream (maintained by pszymkowiak)
cargo install --git https://github.com/ekjotsinghmakhija/prltc

# OR if published to crates.io
cargo install prltc
```

⚠️ **WARNING**: `cargo install prltc` from crates.io might install the wrong package (Type Kit instead of Token Killer). Always verify with `prltc gain` after installation.

### Alternative: Pre-built Binaries

Download from [ekjotsinghmakhija/releases](https://github.com/ekjotsinghmakhija/prltc/releases):
- macOS: `prltc-x86_64-apple-darwin.tar.gz` / `prltc-aarch64-apple-darwin.tar.gz`
- Linux: `prltc-x86_64-unknown-linux-gnu.tar.gz` / `prltc-aarch64-unknown-linux-gnu.tar.gz`
- Windows: `prltc-x86_64-pc-windows-msvc.zip`

## Quick Start

```bash
# 1. Verify installation
prltc gain  # Must show token stats, not "command not found"

# 2. Initialize for Claude Code (RECOMMENDED: hook-first mode)
prltc init --global
# → Installs hook + creates slim PRLTC.md (10 lines, 99.5% token savings)
# → Follow printed instructions to add hook to ~/.claude/settings.json

# 3. Test it works
prltc git status  # Should show ultra-compact output
prltc init --show # Verify hook is installed and executable

# Alternative modes:
# prltc init --global --claude-md  # Legacy: full injection (137 lines)
# prltc init                       # Local project only (./CLAUDE.md)
```

**New in v0.9.5**: Hook-first installation eliminates ~2000 tokens from Claude's context while maintaining full PRLTC functionality through transparent command rewriting.

## Global Flags

```bash
-u, --ultra-compact    # ASCII icons, inline format (extra token savings)
-v, --verbose          # Increase verbosity (-v, -vv, -vvv)
```

## Commands

### Files
```bash
prltc ls .                        # Token-optimized directory tree
prltc read file.rs                # Smart file reading
prltc read file.rs -l aggressive  # Signatures only (strips bodies)
prltc smart file.rs               # 2-line heuristic code summary
prltc find "*.rs" .               # Compact find results
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
prltc gh pr list                   # Compact PR listing
prltc gh pr view 42                # PR details + checks summary
prltc gh issue list                # Compact issue listing
prltc gh run list                  # Workflow run status
prltc wget https://example.com    # Download, strip progress bars
prltc config                       # Show config (--create to generate)
prltc ruff check                   # Python linting (JSON, 80% reduction)
prltc pytest                       # Python tests (failures only, 90% reduction)
prltc pip list                     # Python packages (auto-detect uv, 70% reduction)
prltc go test                      # Go tests (NDJSON, 90% reduction)
prltc golangci-lint run            # Go linting (JSON, 85% reduction)
```

### Data & Analytics
```bash
prltc json config.json            # Structure without values
prltc deps                        # Dependencies summary
prltc env -f AWS                  # Filtered env vars

# Token Savings Analytics (includes execution time metrics)
prltc gain                        # Summary stats with total exec time
prltc gain --graph                # With ASCII graph of last 30 days
prltc gain --history              # With recent command history (10)
prltc gain --quota --tier 20x     # Monthly quota analysis (pro/5x/20x)

# Temporal Breakdowns (includes time metrics per period)
prltc gain --daily                # Day-by-day with avg execution time
prltc gain --weekly               # Week-by-week breakdown
prltc gain --monthly              # Month-by-month breakdown
prltc gain --all                  # All breakdowns combined

# Export Formats (includes total_time_ms and avg_time_ms fields)
prltc gain --all --format json    # JSON export for APIs/dashboards
prltc gain --all --format csv     # CSV export for Excel/analysis
```

> 📖 **API Documentation**: For programmatic access to tracking data (Rust library usage, CI/CD integration, custom dashboards), see [docs/tracking.md](docs/tracking.md).

### Discover — Find Missed Savings

Scans your Claude Code session history to find commands where prltc would have saved tokens. Use it to:
- **Measure what you're missing** — see exactly how many tokens you could save
- **Identify habits** — find which commands you keep running without prltc
- **Spot new opportunities** — see unhandled commands that could become prltc features

```bash
prltc discover                    # Current project, last 30 days
prltc discover --all              # All Claude Code projects
prltc discover --all --since 7    # Last 7 days across all projects
prltc discover -p aristote        # Filter by project name (substring)
prltc discover --format json      # Machine-readable output
```

Example output:
```
PRLTC Discover -- Savings Opportunities
====================================================
Scanned: 142 sessions (last 30 days), 1786 Bash commands
Already using PRLTC: 108 commands (6%)

MISSED SAVINGS -- Commands PRLTC already handles
----------------------------------------------------
Command              Count    PRLTC Equivalent        Est. Savings
git log                434    prltc git               ~55.9K tokens
cargo test             203    prltc cargo             ~49.9K tokens
ls -la                 107    prltc ls                ~11.8K tokens
gh pr                   80    prltc gh                ~10.4K tokens
----------------------------------------------------
Total: 986 commands -> ~143.9K tokens saveable

TOP UNHANDLED COMMANDS -- open an issue?
----------------------------------------------------
Command              Count    Example
git checkout            84    git checkout feature/my-branch
cargo run               32    cargo run -- gain --help
----------------------------------------------------
-> github.com/ekjotsinghmakhija/prltc/issues
```

### Containers
```bash
prltc docker ps                   # Compact container list
prltc docker images               # Compact image list
prltc docker logs <container>     # Deduplicated logs
prltc kubectl pods                # Compact pod list
prltc kubectl logs <pod>          # Deduplicated logs
prltc kubectl services             # Compact service list
```

### JavaScript / TypeScript Stack
```bash
prltc lint                         # ESLint grouped by rule/file
prltc lint biome                   # Supports other linters too
prltc tsc                          # TypeScript errors grouped by file
prltc next build                   # Next.js build compact output
prltc prettier --check .           # Files needing formatting
prltc vitest run                   # Test failures only
prltc playwright test              # E2E results (failures only)
prltc prisma generate              # Schema generation (no ASCII art)
prltc prisma migrate dev --name x  # Migration summary
prltc prisma db-push               # Schema push summary
```

### Python & Go Stack
```bash
# Python
prltc ruff check                   # Ruff linter (JSON, 80% reduction)
prltc ruff format                  # Ruff formatter (text filter)
prltc pytest                       # Test failures with state machine parser (90% reduction)
prltc pip list                     # Package list (auto-detect uv, 70% reduction)
prltc pip install <package>        # Install with compact output
prltc pip outdated                 # Outdated packages (85% reduction)

# Go
prltc go test                      # NDJSON streaming parser (90% reduction)
prltc go build                     # Build errors only (80% reduction)
prltc go vet                       # Vet issues (75% reduction)
prltc golangci-lint run            # JSON grouped by rule (85% reduction)
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

## Configuration

### Installation Modes

| Command | Scope | Hook | PRLTC.md | CLAUDE.md | Tokens in Context | Use Case |
|---------|-------|------|--------|-----------|-------------------|----------|
| `prltc init -g` | Global | ✅ | ✅ (10 lines) | @PRLTC.md | ~10 | **Recommended**: All projects, automatic |
| `prltc init -g --claude-md` | Global | ❌ | ❌ | Full (137 lines) | ~2000 | Legacy compatibility |
| `prltc init -g --hook-only` | Global | ✅ | ❌ | Nothing | 0 | Minimal setup, hook-only |
| `prltc init` | Local | ❌ | ❌ | Full (137 lines) | ~2000 | Single project, no hook |

```bash
prltc init --show         # Show current configuration
prltc init -g             # Install hook + PRLTC.md (recommended)
prltc init -g --claude-md # Legacy: full injection into CLAUDE.md
prltc init                # Local project: full injection into ./CLAUDE.md
```

### Installation Flags

**Settings.json Control**:
```bash
prltc init -g                 # Default: prompt to patch [y/N]
prltc init -g --auto-patch    # Patch settings.json without prompting
prltc init -g --no-patch      # Skip patching, show manual instructions
```

**Mode Control**:
```bash
prltc init -g --claude-md     # Legacy: full 137-line injection (no hook)
prltc init -g --hook-only     # Hook only, no PRLTC.md
```

**Uninstall**:
```bash
prltc init -g --uninstall     # Remove all PRLTC artifacts
```

**What is settings.json?**
Claude Code configuration file that registers the PRLTC hook. The hook transparently rewrites commands (e.g., `git status` → `prltc git status`) before execution. Without this registration, Claude won't use the hook.

**Backup Behavior**:
PRLTC creates `~/.claude/settings.json.bak` before making changes. If something breaks, restore with:
```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

**Migration**: If you previously used `prltc init -g` with the old system (137-line injection), simply re-run `prltc init -g` to automatically migrate to the new hook-first approach.

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

### Custom Database Path

By default, PRLTC stores tracking data in `~/.local/share/prltc/history.db`. You can override this:

**Environment variable** (highest priority):
```bash
export PRLTC_DB_PATH="/path/to/custom.db"
```

**Config file** (`~/.config/prltc/config.toml`):
```toml
[tracking]
database_path = "/path/to/custom.db"
```

Priority: `PRLTC_DB_PATH` env var > `config.toml` > default location.

### Tee: Full Output Recovery

When PRLTC filters command output, LLM agents lose failure details (stack traces, assertion messages) and may re-run the same command 2-3 times. The **tee** feature saves raw output to a file so the agent can read it without re-executing.

**How it works**: On command failure, PRLTC writes the full unfiltered output to `~/.local/share/prltc/tee/` and prints a one-line hint:
```
✓ cargo test: 15 passed (1 suite, 0.01s)
[full output: ~/.local/share/prltc/tee/1707753600_cargo_test.log]
```

The agent reads the file instead of re-running the command — saving tokens.

**Default behavior**: Tee only on failures (exit code != 0), skip outputs < 500 chars.

**Config** (`~/.config/prltc/config.toml`):
```toml
[tee]
enabled = true          # default: true
mode = "failures"       # "failures" (default), "always", or "never"
max_files = 20          # max files to keep (oldest rotated out)
max_file_size = 1048576 # 1MB per file max
# directory = "/custom/path"  # override default location
```

**Environment overrides**:
- `PRLTC_TEE=0` — disable tee entirely
- `PRLTC_TEE_DIR=/path` — override output directory

**Supported commands**: cargo (build/test/clippy/check/install/nextest), vitest, pytest, lint (eslint/biome/ruff/pylint/mypy), tsc, go (test/build/vet), err, test.

## Auto-Rewrite Hook (Recommended)

The most effective way to use prltc is with the **auto-rewrite hook** for Claude Code. Instead of relying on CLAUDE.md instructions (which subagents may ignore), this hook transparently intercepts Bash commands and rewrites them to their prltc equivalents before execution.

**Result**: 100% prltc adoption across all conversations and subagents, zero token overhead in Claude's context.

### What Are Hooks?

**For Beginners**:
Claude Code hooks are scripts that run before/after Claude executes commands. PRLTC uses a **PreToolUse** hook that intercepts Bash commands and rewrites them (e.g., `git status` → `prltc git status`) before execution. This is **transparent** - Claude never sees the rewrite, it just gets optimized output.

**Why settings.json?**
Claude Code reads `~/.claude/settings.json` to find registered hooks. Without this file, Claude doesn't know the PRLTC hook exists. Think of it as the hook registry.

**Is it safe?**
Yes. PRLTC creates a backup (`settings.json.bak`) before changes. The hook is read-only (it only modifies command strings, never deletes files or accesses secrets). Review the hook script at `~/.claude/hooks/prltc-rewrite.sh` anytime.

### How It Works

The hook runs as a Claude Code [PreToolUse hook](https://docs.anthropic.com/en/docs/claude-code/hooks). When Claude Code is about to execute a Bash command like `git status`, the hook rewrites it to `prltc git status` before the command reaches the shell. Claude Code never sees the rewrite — it's transparent.

### Quick Install (Automated)

```bash
prltc init -g
# → Installs hook to ~/.claude/hooks/prltc-rewrite.sh (with executable permissions)
# → Creates ~/.claude/PRLTC.md (10 lines, minimal context footprint)
# → Adds @PRLTC.md reference to ~/.claude/CLAUDE.md
# → Prompts: "Patch settings.json? [y/N]"
# → If yes: creates backup (~/.claude/settings.json.bak), patches file

# Verify installation
prltc init --show  # Shows hook status, settings.json registration
```

**Settings.json Patching Options**:
```bash
prltc init -g                 # Default: prompts for consent [y/N]
prltc init -g --auto-patch    # Patch immediately without prompting (CI/CD)
prltc init -g --no-patch      # Skip patching, print manual JSON snippet
```

**What is settings.json?**
Claude Code's configuration file that registers the PRLTC hook. Without this, Claude won't use the hook. PRLTC backs up the file before changes (`settings.json.bak`).

**Restart Required**: After installation, restart Claude Code, then test with `git status`.

### Manual Install (Fallback)

If automatic patching fails or you prefer manual control:

```bash
# 1. Install hook and PRLTC.md
prltc init -g --no-patch  # Prints JSON snippet

# 2. Manually edit ~/.claude/settings.json (add the printed snippet)

# 3. Restart Claude Code
```

**Alternative: Full manual setup**

```bash
# 1. Copy the hook script
mkdir -p ~/.claude/hooks
cp .claude/hooks/prltc-rewrite.sh ~/.claude/hooks/prltc-rewrite.sh
chmod +x ~/.claude/hooks/prltc-rewrite.sh

# 2. Add to ~/.claude/settings.json under hooks.PreToolUse:
```

Add this entry to the `PreToolUse` array in `~/.claude/settings.json`:

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

### Per-Project Install

The hook is included in this repository at `.claude/hooks/prltc-rewrite.sh`. To use it in another project, copy the hook and add the same settings.json entry using a relative path or project-level `.claude/settings.json`.

### Commands Rewritten

| Raw Command | Rewritten To |
|-------------|-------------|
| `git status/diff/log/add/commit/push/pull/branch/fetch/stash` | `prltc git ...` |
| `gh pr/issue/run` | `prltc gh ...` |
| `cargo test/build/clippy` | `prltc cargo ...` |
| `cat <file>` | `prltc read <file>` |
| `rg/grep <pattern>` | `prltc grep <pattern>` |
| `ls` | `prltc ls` |
| `vitest/pnpm test` | `prltc vitest run` |
| `tsc/pnpm tsc` | `prltc tsc` |
| `eslint/pnpm lint` | `prltc lint` |
| `prettier` | `prltc prettier` |
| `playwright` | `prltc playwright` |
| `prisma` | `prltc prisma` |
| `ruff check/format` | `prltc ruff ...` |
| `pytest` | `prltc pytest` |
| `pip list/install/outdated` | `prltc pip ...` |
| `go test/build/vet` | `prltc go ...` |
| `golangci-lint run` | `prltc golangci-lint run` |
| `docker ps/images/logs` | `prltc docker ...` |
| `kubectl get/logs` | `prltc kubectl ...` |
| `curl` | `prltc curl` |
| `pnpm list/ls/outdated` | `prltc pnpm ...` |

Commands already using `prltc`, heredocs (`<<`), and unrecognized commands pass through unchanged.

### Alternative: Suggest Hook (Non-Intrusive)

If you prefer Claude Code to **suggest** prltc usage rather than automatically rewriting commands, use the **suggest hook** pattern instead. This emits a system reminder when prltc-compatible commands are detected, without modifying the command execution.

**Comparison**:

| Aspect | Auto-Rewrite Hook | Suggest Hook |
|--------|-------------------|--------------|
| **Strategy** | Intercepts and modifies command before execution | Emits system reminder when prltc-compatible command detected |
| **Effect** | Claude Code never sees the original command | Claude Code receives hint to use prltc, decides autonomously |
| **Adoption** | 100% (forced) | ~70-85% (depends on Claude Code's adherence to instructions) |
| **Use Case** | Production workflows, guaranteed savings | Learning mode, auditing, user preference for explicit control |
| **Overhead** | Zero (transparent rewrite) | Minimal (reminder message in context) |

**When to use suggest over rewrite**:
- You want to audit which commands Claude Code chooses to run
- You're learning prltc patterns and want visibility into the rewrite logic
- You prefer Claude Code to make explicit decisions rather than transparent rewrites
- You want to preserve exact command execution for debugging

#### Suggest Hook Setup

**1. Create the suggest hook script**

```bash
mkdir -p ~/.claude/hooks
cp .claude/hooks/prltc-suggest.sh ~/.claude/hooks/prltc-suggest.sh
chmod +x ~/.claude/hooks/prltc-suggest.sh
```

**2. Add to `~/.claude/settings.json`**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/prltc-suggest.sh"
          }
        ]
      }
    ]
  }
}
```

The suggest hook detects the same commands as the rewrite hook but outputs a `systemMessage` instead of `updatedInput`, informing Claude Code that an prltc alternative exists.

## Uninstalling PRLTC

**Complete Removal (Global Only)**:
```bash
prltc init -g --uninstall

# Removes:
#   - ~/.claude/hooks/prltc-rewrite.sh
#   - ~/.claude/PRLTC.md
#   - @PRLTC.md reference from ~/.claude/CLAUDE.md
#   - PRLTC hook entry from ~/.claude/settings.json

# Restart Claude Code after uninstall
```

**Restore from Backup** (if needed):
```bash
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

**Local Projects**: Manually remove PRLTC instructions from `./CLAUDE.md`

**Binary Removal**:
```bash
# If installed via cargo
cargo uninstall prltc

# If installed via package manager
brew uninstall prltc          # macOS Homebrew
sudo apt remove prltc         # Debian/Ubuntu
sudo dnf remove prltc         # Fedora/RHEL
```

## Documentation

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - ⚠️ Fix common issues (wrong prltc installed, missing commands, PATH issues)
- **[INSTALL.md](INSTALL.md)** - Detailed installation guide with verification steps
- **[AUDIT_GUIDE.md](docs/AUDIT_GUIDE.md)** - Complete guide to token savings analytics, temporal breakdowns, and data export
- **[CLAUDE.md](CLAUDE.md)** - Claude Code integration instructions and project context
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture and development guide
- **[SECURITY.md](SECURITY.md)** - Security policy, vulnerability reporting, and PR review process

## Troubleshooting

### Settings.json Patching Failed

**Problem**: `prltc init -g` fails to patch settings.json

**Solutions**:
```bash
# Check if settings.json is valid JSON
cat ~/.claude/settings.json | python3 -m json.tool

# Use manual patching
prltc init -g --no-patch  # Prints JSON snippet

# Restore from backup
cp ~/.claude/settings.json.bak ~/.claude/settings.json

# Check permissions
ls -la ~/.claude/settings.json
chmod 644 ~/.claude/settings.json
```

### Hook Not Working After Install

**Problem**: Commands still not using PRLTC after `prltc init -g`

**Solutions**:
```bash
# Verify hook is registered
prltc init --show

# Check settings.json manually
cat ~/.claude/settings.json | grep prltc-rewrite

# Restart Claude Code (critical step!)

# Test with a command
git status  # Should use prltc automatically
```

### Uninstall Didn't Remove Everything

**Problem**: PRLTC traces remain after `prltc init -g --uninstall`

**Manual Cleanup**:
```bash
# Remove hook
rm ~/.claude/hooks/prltc-rewrite.sh

# Remove PRLTC.md
rm ~/.claude/PRLTC.md

# Remove @PRLTC.md reference
nano ~/.claude/CLAUDE.md  # Delete @PRLTC.md line

# Remove from settings.json
nano ~/.claude/settings.json  # Remove PRLTC hook entry

# Restore from backup
cp ~/.claude/settings.json.bak ~/.claude/settings.json
```

See **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** for more issues and solutions.

## For Maintainers

### Security Review Workflow

PRLTC implements a comprehensive 3-layer security review process for external PRs:

#### Layer 1: Automated GitHub Action
Every PR triggers `.github/workflows/security-check.yml`:
- **Cargo audit**: CVE detection in dependencies
- **Critical files alert**: Flags modifications to high-risk files (runner.rs, tracking.rs, Cargo.toml, workflows)
- **Dangerous pattern scanning**: Shell injection, network operations, unsafe code, panic risks
- **Dependency auditing**: Supply chain verification for new crates
- **Clippy security lints**: Enforces Rust safety best practices

Results appear in the PR's GitHub Actions summary.

#### Layer 2: Claude Code Skill
For comprehensive manual review, maintainers with [Claude Code](https://claude.ai/code) can use:

```bash
/prltc-pr-security <PR_NUMBER>
```

The skill performs:
- **Critical files analysis**: Detects modifications to shell execution, validation, or CI/CD files
- **Dangerous pattern detection**: Identifies shell injection, environment manipulation, exfiltration vectors
- **Supply chain audit**: Verifies new dependencies on crates.io (downloads, maintainer, license)
- **Semantic analysis**: Checks intent vs reality, logic bombs, code quality red flags
- **Structured report generation**: Produces security assessment with risk level and verdict

**Skill installation** (maintainers only):
```bash
# The skill is bundled in the prltc-pr-security directory
# Copy to your Claude skills directory:
cp -r ~/.claude/skills/prltc-pr-security ~/.claude/skills/
```

The skill includes:
- `SKILL.md` - Workflow automation and usage guide
- `critical-files.md` - PRLTC-specific file risk tiers with attack scenarios
- `dangerous-patterns.md` - Regex patterns with exploitation examples
- `checklist.md` - Manual review template

#### Layer 3: Manual Review
For PRs touching critical files or adding dependencies:
- **2 maintainers required** for Cargo.toml, workflows, or Tier 1 files
- **Isolated testing** recommended for high-risk changes
- Follow the checklist in SECURITY.md

See **[SECURITY.md](SECURITY.md)** for complete security policy and review guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please open an issue or PR on GitHub.

**For external contributors**: Your PR will undergo automated security review (see [SECURITY.md](SECURITY.md)). This protects PRLTC's shell execution capabilities against injection attacks and supply chain vulnerabilities.

## Contact

- Website: https://www.github.com/ekjotsinghmakhija/prltc
- Email: ekjotmakhija@gmail.com
- Issues: https://github.com/ekjotsinghmakhija/prltc/issues
