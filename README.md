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
curl -LO https://github.com/pszymkowiak/prltc/releases/latest/download/prltc_0.3.1-1_amd64.deb
sudo dpkg -i prltc_0.3.1-1_amd64.deb
```

### Fedora/RHEL
```bash
curl -LO https://github.com/pszymkowiak/prltc/releases/latest/download/prltc-0.3.1-1.x86_64.rpm
sudo rpm -i prltc-0.3.1-1.x86_64.rpm
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
prltc gh pr list                   # Compact PR listing
prltc gh pr view 42                # PR details + checks summary
prltc gh issue list                # Compact issue listing
prltc gh run list                  # Workflow run status
prltc wget https://example.com    # Download, strip progress bars
prltc config                       # Show config (--create to generate)
```

### Data
```bash
prltc json config.json            # Structure without values
prltc deps                        # Dependencies summary
prltc env -f AWS                  # Filtered env vars

# Token Savings Analytics
prltc gain                        # Summary stats (default view)
prltc gain --graph                # With ASCII graph of last 30 days
prltc gain --history              # With recent command history (10)
prltc gain --quota --tier 20x     # Monthly quota analysis (pro/5x/20x)

# Temporal Breakdowns (NEW in v0.4.0)
prltc gain --daily                # Day-by-day breakdown (all days)
prltc gain --weekly               # Week-by-week breakdown
prltc gain --monthly              # Month-by-month breakdown
prltc gain --all                  # All breakdowns combined

# Export Formats
prltc gain --all --format json    # JSON export for APIs/dashboards
prltc gain --all --format csv     # CSV export for Excel/analysis
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

## Documentation

- **[AUDIT_GUIDE.md](docs/AUDIT_GUIDE.md)** - Complete guide to token savings analytics, temporal breakdowns, and data export
- **[CLAUDE.md](CLAUDE.md)** - Claude Code integration instructions and project context
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture and development guide

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please open an issue or PR on GitHub.
