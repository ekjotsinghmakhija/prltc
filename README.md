<p align="center">
  
</p>

<p align="center">
  <strong>High-performance CLI proxy that reduces LLM token consumption by 60-90%</strong>
</p>

<p align="center">
  <a href="https://github.com/ekjotsinghmakhija/prltc/actions"></a>
  <a href="https://github.com/ekjotsinghmakhija/prltc/releases"></a>
  <a href="https://opensource.org/licenses/MIT"></a>
  
  <a href="https://formulae.brew.sh/formula/prltc"></a>
</p>

<p align="center">
  <a href="https://www.github.com/ekjotsinghmakhija/prltc">Website</a> &bull;
  <a href="#installation">Install</a> &bull;
  <a href="docs/TROUBLESHOOTING.md">Troubleshooting</a> &bull;
  <a href="ARCHITECTURE.md">Architecture</a> &bull;
  
</p>

<p align="center">
  <a href="README.md">English</a> &bull;
  <a href="README_fr.md">Francais</a> &bull;
  <a href="README_zh.md">中文</a> &bull;
  <a href="README_ja.md">日本語</a> &bull;
  <a href="README_ko.md">한국어</a> &bull;
  <a href="README_es.md">Espanol</a>
</p>

---

prltc filters and compresses command outputs before they reach your LLM context. Single Rust binary, 100+ supported commands, <10ms overhead.

## Token Savings (30-min Claude Code Session)

| Operation | Frequency | Standard | prltc | Savings |
|-----------|-----------|----------|-----|---------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `git diff` | 5x | 10,000 | 2,500 | -75% |
| `git log` | 5x | 2,500 | 500 | -80% |
| `git add/commit/push` | 8x | 1,600 | 120 | -92% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| `ruff check` | 3x | 3,000 | 600 | -80% |
| `pytest` | 4x | 8,000 | 800 | -90% |
| `go test` | 3x | 6,000 | 600 | -90% |
| `docker ps` | 3x | 900 | 180 | -80% |
| **Total** | | **~118,000** | **~23,900** | **-80%** |

> Estimates based on medium-sized TypeScript/Rust projects. Actual savings vary by project size.

## Installation

### Homebrew (recommended)

```bash
brew install prltc
```

### Quick Install (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

> Installs to `~/.local/bin`. Add to PATH if needed:
> ```bash
> echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc  # or ~/.zshrc
> ```

### Cargo

```bash
cargo install --git https://github.com/ekjotsinghmakhija/prltc
```

### Pre-built Binaries

Download from [releases](https://github.com/ekjotsinghmakhija/prltc/releases):
- macOS: `prltc-x86_64-apple-darwin.tar.gz` / `prltc-aarch64-apple-darwin.tar.gz`
- Linux: `prltc-x86_64-unknown-linux-musl.tar.gz` / `prltc-aarch64-unknown-linux-gnu.tar.gz`
- Windows: `prltc-x86_64-pc-windows-msvc.zip`

### Verify Installation

```bash
prltc --version   # Should show "prltc 0.28.2"
prltc gain        # Should show token savings stats
```

> **Name collision warning**: Another project named "prltc" (Rust Type Kit) exists on crates.io. If `prltc gain` fails, you have the wrong package. Use `cargo install --git` above instead.

## Quick Start

```bash
# 1. Install for your AI tool
prltc init -g                     # Claude Code / Copilot (default)
prltc init -g --gemini            # Gemini CLI
prltc init -g --codex             # Codex (OpenAI)
prltc init -g --agent cursor      # Cursor
prltc init --agent windsurf       # Windsurf
prltc init --agent cline          # Cline / Roo Code

# 2. Restart your AI tool, then test
git status  # Automatically rewritten to prltc git status
```

The hook transparently rewrites Bash commands (e.g., `git status` -> `prltc git status`) before execution. Claude never sees the rewrite, it just gets compressed output.

**Important:** the hook only runs on Bash tool calls. Claude Code built-in tools like `Read`, `Grep`, and `Glob` do not pass through the Bash hook, so they are not auto-rewritten. To get PRLTC's compact output for those workflows, use shell commands (`cat`/`head`/`tail`, `rg`/`grep`, `find`) or call `prltc read`, `prltc grep`, or `prltc find` directly.

## How It Works

```
  Without prltc:                                    With prltc:

  Claude  --git status-->  shell  -->  git         Claude  --git status-->  PRLTC  -->  git
    ^                                   |            ^                      |          |
    |        ~2,000 tokens (raw)        |            |   ~200 tokens        | filter   |
    +-----------------------------------+            +------- (filtered) ---+----------+
```

Four strategies applied per command type:

1. **Smart Filtering** - Removes noise (comments, whitespace, boilerplate)
2. **Grouping** - Aggregates similar items (files by directory, errors by type)
3. **Truncation** - Keeps relevant context, cuts redundancy
4. **Deduplication** - Collapses repeated log lines with counts

## Commands

### Files
```bash
prltc ls .                        # Token-optimized directory tree
prltc read file.rs                # Smart file reading
prltc read file.rs -l aggressive  # Signatures only (strips bodies)
prltc smart file.rs               # 2-line heuristic code summary
prltc find "*.rs" .               # Compact find results
prltc grep "pattern" .            # Grouped search results
prltc diff file1 file2            # Condensed diff
```

### Git
```bash
prltc git status                  # Compact status
prltc git log -n 10               # One-line commits
prltc git diff                    # Condensed diff
prltc git add                     # -> "ok"
prltc git commit -m "msg"         # -> "ok abc1234"
prltc git push                    # -> "ok main"
prltc git pull                    # -> "ok 3 files +10 -2"
```

### GitHub CLI
```bash
prltc gh pr list                  # Compact PR listing
prltc gh pr view 42               # PR details + checks
prltc gh issue list               # Compact issue listing
prltc gh run list                 # Workflow run status
```

### Test Runners
```bash
prltc test cargo test             # Show failures only (-90%)
prltc err npm run build           # Errors/warnings only
prltc vitest run                  # Vitest compact (failures only)
prltc playwright test             # E2E results (failures only)
prltc pytest                      # Python tests (-90%)
prltc go test                     # Go tests (NDJSON, -90%)
prltc cargo test                  # Cargo tests (-90%)
prltc rake test                   # Ruby minitest (-90%)
prltc rspec                       # RSpec tests (JSON, -60%+)
```

### Build & Lint
```bash
prltc lint                        # ESLint grouped by rule/file
prltc lint biome                  # Supports other linters
prltc tsc                         # TypeScript errors grouped by file
prltc next build                  # Next.js build compact
prltc prettier --check .          # Files needing formatting
prltc cargo build                 # Cargo build (-80%)
prltc cargo clippy                # Cargo clippy (-80%)
prltc ruff check                  # Python linting (JSON, -80%)
prltc golangci-lint run           # Go linting (JSON, -85%)
prltc rubocop                     # Ruby linting (JSON, -60%+)
```

### Package Managers
```bash
prltc pnpm list                   # Compact dependency tree
prltc pip list                    # Python packages (auto-detect uv)
prltc pip outdated                # Outdated packages
prltc bundle install              # Ruby gems (strip Using lines)
prltc prisma generate             # Schema generation (no ASCII art)
```

### Containers
```bash
prltc docker ps                   # Compact container list
prltc docker images               # Compact image list
prltc docker logs <container>     # Deduplicated logs
prltc docker compose ps           # Compose services
prltc kubectl pods                # Compact pod list
prltc kubectl logs <pod>          # Deduplicated logs
prltc kubectl services            # Compact service list
```

### Data & Analytics
```bash
prltc json config.json            # Structure without values
prltc deps                        # Dependencies summary
prltc env -f AWS                  # Filtered env vars
prltc log app.log                 # Deduplicated logs
prltc curl <url>                  # Auto-detect JSON + schema
prltc wget <url>                  # Download, strip progress bars
prltc summary <long command>      # Heuristic summary
prltc proxy <command>             # Raw passthrough + tracking
```

### Token Savings Analytics
```bash
prltc gain                        # Summary stats
prltc gain --graph                # ASCII graph (last 30 days)
prltc gain --history              # Recent command history
prltc gain --daily                # Day-by-day breakdown
prltc gain --all --format json    # JSON export for dashboards

prltc discover                    # Find missed savings opportunities
prltc discover --all --since 7    # All projects, last 7 days

prltc session                     # Show PRLTC adoption across recent sessions
```

## Global Flags

```bash
-u, --ultra-compact    # ASCII icons, inline format (extra token savings)
-v, --verbose          # Increase verbosity (-v, -vv, -vvv)
```

## Examples

**Directory listing:**
```
# ls -la (45 lines, ~800 tokens)        # prltc ls (12 lines, ~150 tokens)
drwxr-xr-x  15 user staff 480 ...       my-project/
-rw-r--r--   1 user staff 1234 ...       +-- src/ (8 files)
...                                      |   +-- main.rs
                                         +-- Cargo.toml
```

**Git operations:**
```
# git push (15 lines, ~200 tokens)       # prltc git push (1 line, ~10 tokens)
Enumerating objects: 5, done.             ok main
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
...
```

**Test output:**
```
# cargo test (200+ lines on failure)     # prltc test cargo test (~20 lines)
running 15 tests                          FAILED: 2/15 tests
test utils::test_parse ... ok               test_edge_case: assertion failed
test utils::test_format ... ok              test_overflow: panic at utils.rs:18
...
```

## Auto-Rewrite Hook

The most effective way to use prltc. The hook transparently intercepts Bash commands and rewrites them to prltc equivalents before execution.

**Result**: 100% prltc adoption across all conversations and subagents, zero token overhead.

**Scope note:** this only applies to Bash tool calls. Claude Code built-in tools such as `Read`, `Grep`, and `Glob` bypass the hook, so use shell commands or explicit `prltc` commands when you want PRLTC filtering there.

### Setup

```bash
prltc init -g                 # Install hook + PRLTC.md (recommended)
prltc init -g --opencode      # OpenCode plugin (instead of Claude Code)
prltc init -g --auto-patch    # Non-interactive (CI/CD)
prltc init -g --hook-only     # Hook only, no PRLTC.md
prltc init --show             # Verify installation
```

After install, **restart Claude Code**.

## Supported AI Tools

PRLTC supports 9 AI coding tools. Each integration transparently rewrites shell commands to `prltc` equivalents for 60-90% token savings.

| Tool | Install | Method |
|------|---------|--------|
| **Claude Code** | `prltc init -g` | PreToolUse hook (bash) |
| **GitHub Copilot** | `prltc init -g` | PreToolUse hook (`prltc hook copilot`) |
| **Cursor** | `prltc init -g --agent cursor` | preToolUse hook (hooks.json) |
| **Gemini CLI** | `prltc init -g --gemini` | BeforeTool hook (`prltc hook gemini`) |
| **Codex** | `prltc init -g --codex` | AGENTS.md + PRLTC.md instructions |
| **Windsurf** | `prltc init --agent windsurf` | .windsurfrules (project-scoped) |
| **Cline / Roo Code** | `prltc init --agent cline` | .clinerules (project-scoped) |
| **OpenCode** | `prltc init -g --opencode` | Plugin TS (tool.execute.before) |
| **OpenClaw** | `openclaw plugins install ./openclaw` | Plugin TS (before_tool_call) |

### Claude Code (default)

```bash
prltc init -g                 # Install hook + PRLTC.md
prltc init -g --auto-patch    # Non-interactive (CI/CD)
prltc init --show             # Verify installation
prltc init -g --uninstall     # Remove
```

### GitHub Copilot (VS Code + CLI)

```bash
prltc init -g                 # Same hook as Claude Code
```

The hook auto-detects Copilot format (VS Code `runTerminalCommand` or CLI `toolName: bash`) and rewrites commands. Works with both Copilot Chat in VS Code and `copilot` CLI.

### Cursor

```bash
prltc init -g --agent cursor
```

Creates `~/.cursor/hooks/prltc-rewrite.sh` + patches `~/.cursor/hooks.json` with preToolUse matcher. Works with both Cursor editor and `cursor-agent` CLI.

### Gemini CLI

```bash
prltc init -g --gemini
prltc init -g --gemini --uninstall
```

Creates `~/.gemini/hooks/prltc-hook-gemini.sh` + patches `~/.gemini/settings.json` with BeforeTool hook.

### Codex (OpenAI)

```bash
prltc init -g --codex
```

Creates `~/.codex/PRLTC.md` + `~/.codex/AGENTS.md` with `@PRLTC.md` reference. Codex reads these as global instructions.

### Windsurf

```bash
prltc init --agent windsurf
```

Creates `.windsurfrules` in the current project. Cascade reads rules and prefixes commands with `prltc`.

### Cline / Roo Code

```bash
prltc init --agent cline
```

Creates `.clinerules` in the current project. Cline reads rules and prefixes commands with `prltc`.

### OpenCode

```bash
prltc init -g --opencode
```

Creates `~/.config/opencode/plugins/prltc.ts`. Uses `tool.execute.before` hook.

### OpenClaw

```bash
openclaw plugins install ./openclaw
```

Plugin in `openclaw/` directory. Uses `before_tool_call` hook, delegates to `prltc rewrite`.

### Commands Rewritten

| Raw Command | Rewritten To |
|-------------|-------------|
| `git status/diff/log/add/commit/push/pull` | `prltc git ...` |
| `gh pr/issue/run` | `prltc gh ...` |
| `cargo test/build/clippy` | `prltc cargo ...` |
| `cat/head/tail <file>` | `prltc read <file>` |
| `rg/grep <pattern>` | `prltc grep <pattern>` |
| `ls` | `prltc ls` |
| `vitest/jest` | `prltc vitest run` |
| `tsc` | `prltc tsc` |
| `eslint/biome` | `prltc lint` |
| `prettier` | `prltc prettier` |
| `playwright` | `prltc playwright` |
| `prisma` | `prltc prisma` |
| `ruff check/format` | `prltc ruff ...` |
| `pytest` | `prltc pytest` |
| `pip list/install` | `prltc pip ...` |
| `go test/build/vet` | `prltc go ...` |
| `golangci-lint` | `prltc golangci-lint` |
| `rake test` / `rails test` | `prltc rake test` |
| `rspec` / `bundle exec rspec` | `prltc rspec` |
| `rubocop` / `bundle exec rubocop` | `prltc rubocop` |
| `bundle install/update` | `prltc bundle ...` |
| `docker ps/images/logs` | `prltc docker ...` |
| `kubectl get/logs` | `prltc kubectl ...` |
| `curl` | `prltc curl` |
| `pnpm list/outdated` | `prltc pnpm ...` |

Commands already using `prltc`, heredocs (`<<`), and unrecognized commands pass through unchanged.

## Configuration

### Config File

`~/.config/prltc/config.toml` (macOS: `~/Library/Application Support/prltc/config.toml`):

```toml
[tracking]
database_path = "/path/to/custom.db"  # default: ~/.local/share/prltc/history.db

[hooks]
exclude_commands = ["curl", "playwright"]  # skip rewrite for these

[tee]
enabled = true          # save raw output on failure (default: true)
mode = "failures"       # "failures", "always", or "never"
max_files = 20          # rotation limit
```

### Tee: Full Output Recovery

When a command fails, PRLTC saves the full unfiltered output so the LLM can read it without re-executing:

```
FAILED: 2/15 tests
[full output: ~/.local/share/prltc/tee/1707753600_cargo_test.log]
```

### Uninstall

```bash
prltc init -g --uninstall     # Remove hook, PRLTC.md, settings.json entry
cargo uninstall prltc          # Remove binary
brew uninstall prltc           # If installed via Homebrew
```

## Documentation

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Fix common issues
- **[INSTALL.md](INSTALL.md)** - Detailed installation guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture
- **[SECURITY.md](SECURITY.md)** - Security policy and PR review process
- **[AUDIT_GUIDE.md](docs/AUDIT_GUIDE.md)** - Token savings analytics guide

## Privacy & Telemetry

PRLTC collects **anonymous, aggregate usage metrics** once per day to help prioritize development. This is standard practice for open-source CLI tools.

**What is collected:**
- Device hash (SHA-256 of hostname+username, not reversible)
- PRLTC version, OS, architecture
- Command count (last 24h) and top command names (e.g. "git", "cargo" — no arguments, no file paths)
- Token savings percentage

**What is NOT collected:** source code, file paths, command arguments, secrets, environment variables, or any personally identifiable information.

**Opt-out** (any of these):
```bash
# Environment variable
export PRLTC_TELEMETRY_DISABLED=1

# Or in config file (~/.config/prltc/config.toml)
[telemetry]
enabled = false
```

## Contributing

Contributions welcome! Please open an issue or PR on [GitHub](https://github.com/ekjotsinghmakhija/prltc).

Join the community on .

## License

MIT License - see [LICENSE](LICENSE) for details.
