/*
 * Titanium Engine Core - prltc
 * Copyright (c) 2026 Ekjot Singh
 * Proprietary Clean Room Implementation
 */

use anyhow::{Context, Result};
use std::fs;
use std::path::PathBuf;

// Embedded hook script (guards before set -euo pipefail)
const REWRITE_HOOK: &str = include_str!("../hooks/prltc-rewrite.sh");

// Embedded slim PRLTC awareness instructions
const PRLTC_SLIM: &str = include_str!("../hooks/prltc-awareness.md");

// Legacy full instructions for backward compatibility (--claude-md mode)
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
<!-- /prltc-instructions -->
"##;

/// Main entry point for `prltc init`
pub fn run(global: bool, claude_md: bool, hook_only: bool, verbose: u8) -> Result<()> {
    // Mode selection
    if claude_md {
        // Legacy mode: full injection into CLAUDE.md
        run_claude_md_mode(global, verbose)
    } else if hook_only {
        // Hook-only mode: no PRLTC.md
        run_hook_only_mode(global, verbose)
    } else {
        // Default mode: hook + PRLTC.md (MVP)
        run_default_mode(global, verbose)
    }
}

/// Default mode: hook + slim PRLTC.md + @PRLTC.md reference
#[cfg(not(unix))]
fn run_default_mode(_global: bool, _verbose: u8) -> Result<()> {
    eprintln!("Warning: Hook install only supported on Unix (macOS, Linux).");
    eprintln!("Falling back to --claude-md mode.");
    run_claude_md_mode(_global, _verbose)
}

#[cfg(unix)]
fn run_default_mode(global: bool, verbose: u8) -> Result<()> {
    if !global {
        // Local init: unchanged behavior (full injection into ./CLAUDE.md)
        return run_claude_md_mode(false, verbose);
    }

    let claude_dir = resolve_claude_dir()?;
    let hook_dir = claude_dir.join("hooks");
    let hook_path = hook_dir.join("prltc-rewrite.sh");
    let prltc_md_path = claude_dir.join("PRLTC.md");
    let claude_md_path = claude_dir.join("CLAUDE.md");

    // Ensure directories exist
    fs::create_dir_all(&hook_dir).context("Failed to create ~/.claude/hooks")?;

    // 1. Write hook file
    if hook_path.exists() {
        let existing = fs::read_to_string(&hook_path)?;
        if existing == REWRITE_HOOK {
            if verbose > 0 {
                eprintln!("Hook already up to date: {}", hook_path.display());
            }
        } else {
            fs::write(&hook_path, REWRITE_HOOK).context("Failed to write hook")?;
            if verbose > 0 {
                eprintln!("Updated hook: {}", hook_path.display());
            }
        }
    } else {
        fs::write(&hook_path, REWRITE_HOOK).context("Failed to write hook")?;
        if verbose > 0 {
            eprintln!("Created hook: {}", hook_path.display());
        }
    }

    // 2. chmod +x (Unix only)
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&hook_path, fs::Permissions::from_mode(0o755))
            .context("Failed to set hook permissions")?;
    }

    // 3. Write PRLTC.md
    if prltc_md_path.exists() {
        let existing = fs::read_to_string(&prltc_md_path)?;
        if existing == PRLTC_SLIM {
            if verbose > 0 {
                eprintln!("PRLTC.md already up to date: {}", prltc_md_path.display());
            }
        } else {
            fs::write(&prltc_md_path, PRLTC_SLIM).context("Failed to write PRLTC.md")?;
            if verbose > 0 {
                eprintln!("Updated PRLTC.md: {}", prltc_md_path.display());
            }
        }
    } else {
        fs::write(&prltc_md_path, PRLTC_SLIM).context("Failed to write PRLTC.md")?;
        if verbose > 0 {
            eprintln!("Created PRLTC.md: {}", prltc_md_path.display());
        }
    }

    // 4. Patch CLAUDE.md (add @PRLTC.md, migrate if needed)
    let migrated = patch_claude_md(&claude_md_path, verbose)?;

    // 5. Print success message
    println!("\nPRLTC hook installed (global).\n");
    println!("  Hook:      {}", hook_path.display());
    println!("  PRLTC.md:    {} (10 lines)", prltc_md_path.display());
    println!("  CLAUDE.md: @PRLTC.md reference added");

    if migrated {
        println!("\n  ✅ Migrated: removed 137-line PRLTC block from CLAUDE.md");
        println!("              replaced with @PRLTC.md (10 lines)");
    }

    println!("\n  MANUAL STEP: Add this to ~/.claude/settings.json:");
    println!("  {{");
    println!("    \"hooks\": {{ \"PreToolUse\": [{{");
    println!("      \"matcher\": \"Bash\",");
    println!("      \"hooks\": [{{ \"type\": \"command\",");
    println!("        \"command\": \"{}\"", hook_path.display());
    println!("      }}]");
    println!("    }}]}}");
    println!("  }}");
    println!("\n  Then restart Claude Code. Test with: git status\n");

    Ok(())
}

/// Hook-only mode: just the hook, no PRLTC.md
#[cfg(not(unix))]
fn run_hook_only_mode(_global: bool, _verbose: u8) -> Result<()> {
    eprintln!("Warning: Hook install only supported on Unix (macOS, Linux).");
    Ok(())
}

#[cfg(unix)]
fn run_hook_only_mode(global: bool, _verbose: u8) -> Result<()> {
    if !global {
        eprintln!("Warning: --hook-only only makes sense with --global");
        eprintln!("For local projects, use default mode or --claude-md");
        return Ok(());
    }

    let claude_dir = resolve_claude_dir()?;
    let hook_dir = claude_dir.join("hooks");
    let hook_path = hook_dir.join("prltc-rewrite.sh");

    fs::create_dir_all(&hook_dir).context("Failed to create ~/.claude/hooks")?;

    fs::write(&hook_path, REWRITE_HOOK).context("Failed to write hook")?;

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&hook_path, fs::Permissions::from_mode(0o755))
            .context("Failed to set hook permissions")?;
    }

    println!("\nPRLTC hook installed (hook-only mode).\n");
    println!("  Hook: {}", hook_path.display());
    println!("\n  MANUAL STEP: Add hook to ~/.claude/settings.json (see --global output)");
    println!("  Note: No PRLTC.md created. Claude won't know about meta commands (gain, discover, proxy).\n");

    Ok(())
}

/// Legacy mode: full 137-line injection into CLAUDE.md
fn run_claude_md_mode(global: bool, verbose: u8) -> Result<()> {
    let path = if global {
        resolve_claude_dir()?.join("CLAUDE.md")
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

    if path.exists() {
        let existing = fs::read_to_string(&path)?;

        if existing.contains("<!-- prltc-instructions") {
            println!("✅ {} already contains prltc instructions", path.display());
            return Ok(());
        }

        let new_content = format!("{}\n\n{}", existing.trim(), PRLTC_INSTRUCTIONS);
        fs::write(&path, new_content)?;
        println!("✅ Added prltc instructions to existing {}", path.display());
    } else {
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

/// Patch CLAUDE.md: add @PRLTC.md, migrate if old block exists
fn patch_claude_md(path: &PathBuf, verbose: u8) -> Result<bool> {
    let mut content = if path.exists() {
        fs::read_to_string(path)?
    } else {
        String::new()
    };

    let mut migrated = false;

    // Check for old block and migrate
    if content.contains("<!-- prltc-instructions") {
        let (new_content, did_migrate) = remove_prltc_block(&content);
        if did_migrate {
            content = new_content;
            migrated = true;
            if verbose > 0 {
                eprintln!("Migrated: removed old PRLTC block from CLAUDE.md");
            }
        }
    }

    // Check if @PRLTC.md already present
    if content.contains("@PRLTC.md") {
        if verbose > 0 {
            eprintln!("@PRLTC.md reference already present in CLAUDE.md");
        }
        if migrated {
            fs::write(path, content)?;
        }
        return Ok(migrated);
    }

    // Add @PRLTC.md
    let new_content = if content.is_empty() {
        "@PRLTC.md\n".to_string()
    } else {
        format!("{}\n\n@PRLTC.md\n", content.trim())
    };

    fs::write(path, new_content)?;

    if verbose > 0 {
        eprintln!("Added @PRLTC.md reference to CLAUDE.md");
    }

    Ok(migrated)
}

/// Remove old PRLTC block from CLAUDE.md (migration helper)
fn remove_prltc_block(content: &str) -> (String, bool) {
    if let (Some(start), Some(end)) = (
        content.find("<!-- prltc-instructions"),
        content.find("<!-- /prltc-instructions -->"),
    ) {
        let end_pos = end + "<!-- /prltc-instructions -->".len();
        let before = content[..start].trim_end();
        let after = content[end_pos..].trim_start();

        let result = if after.is_empty() {
            before.to_string()
        } else {
            format!("{}\n\n{}", before, after)
        };

        (result, true) // migrated
    } else if content.contains("<!-- prltc-instructions") {
        eprintln!("Warning: prltc-instructions marker found but no closing marker.");
        eprintln!("Manual cleanup needed.");
        (content.to_string(), false)
    } else {
        (content.to_string(), false)
    }
}

/// Resolve ~/.claude directory with proper home expansion
fn resolve_claude_dir() -> Result<PathBuf> {
    dirs::home_dir()
        .map(|h| h.join(".claude"))
        .context("Cannot determine home directory. Is $HOME set?")
}

/// Show current prltc configuration
pub fn show_config() -> Result<()> {
    let claude_dir = resolve_claude_dir()?;
    let hook_path = claude_dir.join("hooks").join("prltc-rewrite.sh");
    let prltc_md_path = claude_dir.join("PRLTC.md");
    let global_claude_md = claude_dir.join("CLAUDE.md");
    let local_claude_md = PathBuf::from("CLAUDE.md");

    println!("📋 prltc Configuration:\n");

    // Check hook
    if hook_path.exists() {
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let metadata = fs::metadata(&hook_path)?;
            let perms = metadata.permissions();
            let is_executable = perms.mode() & 0o111 != 0;

            let hook_content = fs::read_to_string(&hook_path)?;
            let has_guards =
                hook_content.contains("command -v prltc") && hook_content.contains("command -v jq");

            if is_executable && has_guards {
                println!("✅ Hook: {} (executable, with guards)", hook_path.display());
            } else if !is_executable {
                println!(
                    "⚠️  Hook: {} (NOT executable - run: chmod +x)",
                    hook_path.display()
                );
            } else {
                println!("⚠️  Hook: {} (no guards - outdated)", hook_path.display());
            }
        }

        #[cfg(not(unix))]
        {
            println!("✅ Hook: {} (exists)", hook_path.display());
        }
    } else {
        println!("⚪ Hook: not found");
    }

    // Check PRLTC.md
    if prltc_md_path.exists() {
        println!("✅ PRLTC.md: {} (slim mode)", prltc_md_path.display());
    } else {
        println!("⚪ PRLTC.md: not found");
    }

    // Check global CLAUDE.md
    if global_claude_md.exists() {
        let content = fs::read_to_string(&global_claude_md)?;
        if content.contains("@PRLTC.md") {
            println!("✅ Global (~/.claude/CLAUDE.md): @PRLTC.md reference");
        } else if content.contains("<!-- prltc-instructions") {
            println!(
                "⚠️  Global (~/.claude/CLAUDE.md): old PRLTC block (run: prltc init -g to migrate)"
            );
        } else {
            println!("⚪ Global (~/.claude/CLAUDE.md): exists but prltc not configured");
        }
    } else {
        println!("⚪ Global (~/.claude/CLAUDE.md): not found");
    }

    // Check local CLAUDE.md
    if local_claude_md.exists() {
        let content = fs::read_to_string(&local_claude_md)?;
        if content.contains("prltc") {
            println!("✅ Local (./CLAUDE.md): prltc enabled");
        } else {
            println!("⚪ Local (./CLAUDE.md): exists but prltc not configured");
        }
    } else {
        println!("⚪ Local (./CLAUDE.md): not found");
    }

    println!("\nUsage:");
    println!("  prltc init              # Full injection into local CLAUDE.md");
    println!("  prltc init -g           # Hook + PRLTC.md + @PRLTC.md (recommended)");
    println!("  prltc init -g --claude-md    # Legacy: full injection into ~/.claude/CLAUDE.md");
    println!("  prltc init -g --hook-only    # Hook only, no PRLTC.md");

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_init_mentions_all_top_level_commands() {
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

    #[test]
    fn test_hook_has_guards() {
        assert!(REWRITE_HOOK.contains("command -v prltc"));
        assert!(REWRITE_HOOK.contains("command -v jq"));
        // Guards must be BEFORE set -euo pipefail
        let guard_pos = REWRITE_HOOK.find("command -v prltc").unwrap();
        let set_pos = REWRITE_HOOK.find("set -euo pipefail").unwrap();
        assert!(
            guard_pos < set_pos,
            "Guards must come before set -euo pipefail"
        );
    }

    #[test]
    fn test_migration_removes_old_block() {
        let input = r#"# My Config

<!-- prltc-instructions v2 -->
OLD PRLTC STUFF
<!-- /prltc-instructions -->

More content"#;

        let (result, migrated) = remove_prltc_block(input);
        assert!(migrated);
        assert!(!result.contains("OLD PRLTC STUFF"));
        assert!(result.contains("# My Config"));
        assert!(result.contains("More content"));
    }

    #[test]
    fn test_migration_warns_on_missing_end_marker() {
        let input = "<!-- prltc-instructions v2 -->\nOLD STUFF\nNo end marker";
        let (result, migrated) = remove_prltc_block(input);
        assert!(!migrated);
        assert_eq!(result, input);
    }

    #[test]
    #[cfg(unix)]
    fn test_default_mode_creates_hook_and_prltc_md() {
        let temp = TempDir::new().unwrap();
        let hook_path = temp.path().join("prltc-rewrite.sh");
        let prltc_md_path = temp.path().join("PRLTC.md");

        fs::write(&hook_path, REWRITE_HOOK).unwrap();
        fs::write(&prltc_md_path, PRLTC_SLIM).unwrap();

        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&hook_path, fs::Permissions::from_mode(0o755)).unwrap();

        assert!(hook_path.exists());
        assert!(prltc_md_path.exists());

        let metadata = fs::metadata(&hook_path).unwrap();
        assert!(metadata.permissions().mode() & 0o111 != 0);
    }

    #[test]
    fn test_claude_md_mode_creates_full_injection() {
        // Just verify PRLTC_INSTRUCTIONS constant has the right content
        assert!(PRLTC_INSTRUCTIONS.contains("<!-- prltc-instructions"));
        assert!(PRLTC_INSTRUCTIONS.contains("prltc cargo test"));
        assert!(PRLTC_INSTRUCTIONS.contains("<!-- /prltc-instructions -->"));
        assert!(PRLTC_INSTRUCTIONS.len() > 4000);
    }

    #[test]
    fn test_init_is_idempotent() {
        let temp = TempDir::new().unwrap();
        let claude_md = temp.path().join("CLAUDE.md");

        fs::write(&claude_md, "# My stuff\n\n@PRLTC.md\n").unwrap();

        let content = fs::read_to_string(&claude_md).unwrap();
        let count = content.matches("@PRLTC.md").count();
        assert_eq!(count, 1);
    }

    #[test]
    fn test_local_init_unchanged() {
        // Local init should use claude-md mode
        let temp = TempDir::new().unwrap();
        let claude_md = temp.path().join("CLAUDE.md");

        fs::write(&claude_md, PRLTC_INSTRUCTIONS).unwrap();
        let content = fs::read_to_string(&claude_md).unwrap();

        assert!(content.contains("<!-- prltc-instructions"));
    }
}
