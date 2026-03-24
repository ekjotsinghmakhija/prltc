# prltc - Rust Token Killer



**High-performance CLI proxy to minimize LLM token consumption.**

prltc filters and compresses command outputs before they reach your LLM context, saving 60-90% of tokens on common operations.

## Demo

```bash
# Play the demo locally
asciinema play demo.cast

# Or watch in terminal
./demo.sh
```

<!-- Upload to asciinema.org: asciinema upload demo.cast -->

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

### Homebrew (macOS)
```bash
brew tap pszymkowiak/prltc
brew install prltc
```

### Script (Linux/macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/pszymkowiak/prltc/main/install.sh | sh
```

### Cargo
```bash
cargo install prltc
```

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

## Configuration

prltc reads from `CLAUDE.md` files to instruct Claude Code to use prltc automatically:

```bash
prltc init --show    # Show current configuration
prltc init           # Create local CLAUDE.md
prltc init --global  # Create ~/CLAUDE.md
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please open an issue or PR on GitHub.
