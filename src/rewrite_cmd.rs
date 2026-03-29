/*
 * Titanium Engine Core - prltc
 * Copyright (c) 2026 Ekjot Singh
 * Proprietary Clean Room Implementation
 */

use crate::discover::registry;

/// Run the `prltc rewrite` command.
///
/// Prints the PRLTC-rewritten command to stdout and exits 0.
/// Exits 1 (without output) if the command has no PRLTC equivalent.
///
/// Used by shell hooks to rewrite commands transparently:
/// ```bash
/// REWRITTEN=$(prltc rewrite "$CMD") || exit 0
/// [ "$CMD" = "$REWRITTEN" ] && exit 0  # already PRLTC, skip
/// ```
pub fn run(cmd: &str) -> anyhow::Result<()> {
    let excluded = crate::config::Config::load()
        .map(|c| c.hooks.exclude_commands)
        .unwrap_or_default();

    match registry::rewrite_command(cmd, &excluded) {
        Some(rewritten) => {
            print!("{}", rewritten);
            Ok(())
        }
        None => {
            std::process::exit(1);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_supported_command_succeeds() {
        assert!(registry::rewrite_command("git status", &[]).is_some());
    }

    #[test]
    fn test_run_unsupported_returns_none() {
        assert!(registry::rewrite_command("terraform plan", &[]).is_none());
    }

    #[test]
    fn test_run_already_prltc_returns_some() {
        assert_eq!(
            registry::rewrite_command("prltc git status", &[]),
            Some("prltc git status".into())
        );
    }
}
