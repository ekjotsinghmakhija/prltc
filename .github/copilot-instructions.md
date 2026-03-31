# Copilot Instructions for prltc

**prltc (Rust Token Killer)** is a CLI proxy that filters and compresses command outputs before they reach an LLM context, saving 60–90% of tokens. It wraps common tools (`git`, `cargo`, `grep`, `pnpm`, `go`, etc.) and outputs condensed summaries instead of raw output.

## Using prltc in this session

**Always prefix commands with `prltc` when running shell commands** — this is the entire point of the project and reduces token consumption for every operation you perform.

```bash
# Instead of:              Use:
git status                 prltc git status
git log -10                prltc git log -10
cargo test                 prltc cargo test
cargo clippy --all-targets prltc cargo clippy --all-targets
grep -r "pattern" src/     prltc grep -r "pattern" src/
```

**prltc meta-commands** (always use these directly, no prefix needed):
```bash
prltc gain              # Show token savings analytics for this session
prltc gain --history    # Full command history with per-command savings
prltc discover          # Scan session history for missed prltc opportunities
prltc proxy <cmd>       # Run a command raw (no filtering) but still track it
```

**Verify prltc is installed before starting:**
```bash
prltc --version   # Should print: prltc X.Y.Z
prltc gain        # Should show a dashboard (not "command not found")
```

> ⚠️ **Name collision**: `prltc gain` failing means you have `reachingforthejack/prltc` (Rust Type Kit) installed instead of this project. Run `which prltc` and check the binary source.

## Build, Test & Lint

```bash
# Development build
cargo build

# Run all tests
cargo test

# Run a single test by name
cargo test test_filter_git_log

# Run all tests in a module
cargo test git::tests::

# Run tests with stdout
cargo test -- --nocapture

# Pre-commit gate (must all pass before any PR)
cargo fmt --all --check && cargo clippy --all-targets && cargo test

# Smoke tests (requires installed binary)
bash scripts/test-all.sh
```

PRs target the **`develop`** branch, not `main`. All commits require a DCO sign-off (`git commit -s`).

## Architecture

```
main.rs  ←  Clap Commands enum  →  specialized module (git.rs, *_cmd.rs, etc.)
                                          ↓
                                   execute subprocess
                                          ↓
                                   filter/compress output
                                          ↓
                               tracking::TimedExecution  →  SQLite (~/.local/share/prltc/tracking.db)
```

Key modules:
- **`main.rs`** — Clap `Commands` enum routes every subcommand to its module. Each arm calls `tracking::TimedExecution::start()` before running, then `.track(...)` after.
- **`filter.rs`** — Language-aware filtering with `FilterLevel` (`none` / `minimal` / `aggressive`) and `Language` enum. Used by `read` and `smart` commands.
- **`tracking.rs`** — SQLite persistence for token savings, scoped per project path. Powers `prltc gain`.
- **`tee.rs`** — On filter failure, saves raw output to `~/.local/share/prltc/tee/` and prints a one-line hint so the LLM can re-read without re-running the command.
- **`utils.rs`** — Shared helpers: `truncate`, `strip_ansi`, `execute_command`, package-manager auto-detection (pnpm/yarn/npm/npx).

New commands follow this structure: one file `src/<cmd>_cmd.rs` with a `pub fn run(...)` entry point, registered in the `Commands` enum in `main.rs`.

## Key Conventions

### Error handling
- Use `anyhow::Result` throughout (this is a binary, not a library).
- Always attach context: `operation.context("description")?` — never bare `?` without context.
- No `unwrap()` in production code; `expect("reason")` is acceptable only in tests.
- Every filter must fall back to raw command execution on error — never break the user's workflow.

### Regex
- Compile once with `lazy_static!`, never inside a function body:
  ```rust
  lazy_static! {
      static ref RE: Regex = Regex::new(r"pattern").unwrap();
  }
  ```

### Testing
- Unit tests live **inside the module file** in `#[cfg(test)] mod tests { ... }` — not in `tests/`.
- Fixtures are real captured command output in `tests/fixtures/<cmd>_raw.txt`, loaded with `include_str!("../tests/fixtures/...")`.
- Each test module defines its own local `fn count_tokens(text: &str) -> usize` (word-split approximation) — there is no shared utility for this.
- Token savings assertions use `assert!(savings >= 60.0, ...)`.
- Snapshot tests use `assert_snapshot!()` from the `insta` crate; review with `cargo insta review`.

### Adding a new command
1. Create `src/<cmd>_cmd.rs` with `pub fn run(...)`.
2. Add `mod <cmd>_cmd;` at the top of `main.rs`.
3. Add a variant to the `Commands` enum with `#[arg(trailing_var_arg = true, allow_hyphen_values = true)]` for pass-through flags.
4. Route the variant in the `match` block, wrapping execution with `tracking::TimedExecution`.
5. Write a fixture from real output, then unit tests in the module file.
6. Update `README.md` (command list + savings %) and `CHANGELOG.md`.

### Exit codes
Preserve the underlying command's exit code. Use `std::process::exit(code)` when the child process exits non-zero.

### Performance constraints
- Startup must stay under 10ms — no async runtime (no `tokio`/`async-std`).
- No blocking I/O at startup; config is loaded on-demand.
- Binary size target: <5 MB stripped.

### Branch naming
```
fix(scope): short-description
feat(scope): short-description
chore(scope): short-description
```
`scope` is the affected component (e.g. `git`, `filter`, `tracking`).
