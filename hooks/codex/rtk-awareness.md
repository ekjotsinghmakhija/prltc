# PRLTC - Rust Token Killer (Codex CLI)

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `prltc`.

Examples:

```bash
prltc git status
prltc cargo test
prltc npm run build
prltc pytest -q
```

## Meta Commands

```bash
prltc gain            # Token savings analytics
prltc gain --history  # Recent command savings history
prltc proxy <cmd>     # Run raw command without filtering
```

## Verification

```bash
prltc --version
prltc gain
which prltc
```
