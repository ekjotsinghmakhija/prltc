/*
 * Titanium Engine Core - prltc
 * Copyright (c) 2026 Ekjot Singh
 * Proprietary Clean Room Implementation
 */

use anyhow::Result;
use std::fs;
use std::path::PathBuf;

const PRLTC_INSTRUCTIONS: &str = r##"<!-- prltc-instructions v2 -->
# PRLTC (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `prltc`**. If PRLTC has a dedicated filter, it uses it. If not, it passes through unchanged. This means PRLTC is always safe to use.

**Important**: Even in command chains with `&&`, use `prltc`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
prltc git add . && prltc git commit -m "msg" && prltc git push
```

## PRLTC Commands by Workflow

### Build & Compile (80-90% savings)
```bash
prltc cargo build         # Cargo build output
prltc cargo check         # Cargo check output
prltc cargo clippy        # Clippy warnings grouped by file (80%)
prltc tsc                 # TypeScript errors grouped by file/code (83%)
prltc lint                # ESLint/Biome violations grouped (84%)
prltc prettier --check    # Files needing format only (70%)
prltc next build          # Next.js build with route metrics (87%)
```

### Test (90-99% savings)
```bash
prltc cargo test          # Cargo test failures only (90%)
prltc vitest run          # Vitest failures only (99.5%)
prltc playwright test     # Playwright failures only (94%)
prltc test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
prltc git status          # Compact status
prltc git log             # Compact log (works with all git flags)
prltc git diff            # Compact diff (80%)
prltc git show            # Compact show (80%)
prltc git add             # Ultra-compact confirmations (59%)
prltc git commit          # Ultra-compact confirmations (59%)
prltc git push            # Ultra-compact confirmations
prltc git pull            # Ultra-compact confirmations
prltc git branch          # Compact branch list
prltc git fetch           # Compact fetch
prltc git stash           # Compact stash
prltc git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
prltc gh pr view <num>    # Compact PR view (87%)
prltc gh pr checks        # Compact PR checks (79%)
prltc gh run list         # Compact workflow runs (82%)
prltc gh issue list       # Compact issue list (80%)
prltc gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
prltc pnpm list           # Compact dependency tree (70%)
prltc pnpm outdated       # Compact outdated packages (80%)
prltc pnpm install        # Compact install output (90%)
prltc npm run <script>    # Compact npm script output
prltc npx <cmd>           # Compact npx command output
prltc prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
prltc ls <path>           # Tree format, compact (65%)
prltc read <file>         # Code reading with filtering (60%)
prltc grep <pattern>      # Search grouped by file (75%)
prltc find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
prltc err <cmd>           # Filter errors only from any command
prltc log <file>          # Deduplicated logs with counts
prltc json <file>         # JSON structure without values
prltc deps                # Dependency overview
prltc env                 # Environment variables compact
prltc summary <cmd>       # Smart summary of command output
prltc diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
prltc docker ps           # Compact container list
prltc docker images       # Compact image list
prltc docker logs <c>     # Deduplicated logs
prltc kubectl get         # Compact resource list
prltc kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
prltc curl <url>          # Compact HTTP responses (70%)
prltc wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
prltc gain                # View token savings statistics
prltc gain --history      # View command history with savings
prltc discover            # Analyze Claude Code sessions for missed PRLTC usage
prltc proxy <cmd>         # Run command without filtering (for debugging)
prltc init                # Add PRLTC instructions to CLAUDE.md
prltc init --global       # Add PRLTC to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
"##;

pub fn run(global: bool, verbose: u8) -> Result<()> {
    let path = if global {
        dirs::home_dir()
            .map(|h| h.join(".claude").join("CLAUDE.md"))
            .unwrap_or_else(|| PathBuf::from("~/.claude/CLAUDE.md"))
    } else {
        PathBuf::from("CLAUDE.md")
    };

    if global {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
    }

    if verbose > 0 {
        eprintln!("Writing prltc instructions to: {}", path.display());
    }

    // Check if file exists
    if path.exists() {
        let existing = fs::read_to_string(&path)?;

        // Check if prltc instructions already present using version marker
        if existing.contains("<!-- prltc-instructions") {
            println!("✅ {} already contains prltc instructions", path.display());
            return Ok(());
        }

        // Append to existing file
        let new_content = format!("{}\n\n{}", existing.trim(), PRLTC_INSTRUCTIONS);
        fs::write(&path, new_content)?;
        println!("✅ Added prltc instructions to existing {}", path.display());
    } else {
        // Create new file
        fs::write(&path, PRLTC_INSTRUCTIONS)?;
        println!("✅ Created {} with prltc instructions", path.display());
    }

    if global {
        println!("   Claude Code will now use prltc in all sessions");
    } else {
        println!("   Claude Code will use prltc in this project");
    }

    Ok(())
}

/// Show current prltc configuration
pub fn show_config() -> Result<()> {
    let home_path = dirs::home_dir().map(|h| h.join(".claude").join("CLAUDE.md"));
    let local_path = PathBuf::from("CLAUDE.md");

    println!("📋 prltc Configuration:\n");

    // Check global
    if let Some(hp) = &home_path {
        if hp.exists() {
            let content = fs::read_to_string(hp)?;
            if content.contains("prltc") {
                println!("✅ Global (~/.claude/CLAUDE.md): prltc enabled");
            } else {
                println!("⚪ Global (~/.claude/CLAUDE.md): exists but prltc not configured");
            }
        } else {
            println!("⚪ Global (~/.claude/CLAUDE.md): not found");
        }
    }

    // Check local
    if local_path.exists() {
        let content = fs::read_to_string(&local_path)?;
        if content.contains("prltc") {
            println!("✅ Local (./CLAUDE.md): prltc enabled");
        } else {
            println!("⚪ Local (./CLAUDE.md): exists but prltc not configured");
        }
    } else {
        println!("⚪ Local (./CLAUDE.md): not found");
    }

    println!("\nUsage:");
    println!("  prltc init          # Add prltc to local CLAUDE.md");
    println!("  prltc init --global # Add prltc to global ~/.claude/CLAUDE.md");

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init_mentions_all_top_level_commands() {
        // Verify PRLTC_INSTRUCTIONS mentions key commands
        for cmd in [
            "prltc cargo",
            "prltc gh",
            "prltc vitest",
            "prltc tsc",
            "prltc lint",
            "prltc prettier",
            "prltc next",
            "prltc playwright",
            "prltc prisma",
            "prltc pnpm",
            "prltc npm",
            "prltc curl",
            "prltc git",
            "prltc docker",
            "prltc kubectl",
        ] {
            assert!(
                PRLTC_INSTRUCTIONS.contains(cmd),
                "Missing {cmd} in PRLTC_INSTRUCTIONS"
            );
        }
    }

    #[test]
    fn test_init_has_version_marker() {
        assert!(
            PRLTC_INSTRUCTIONS.contains("<!-- prltc-instructions"),
            "PRLTC_INSTRUCTIONS must have version marker for idempotency"
        );
    }
}
