# PRLTC - Rust Token Killer (Windsurf)

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `prltc` to minimize token consumption.

Examples:

```bash
prltc git status
prltc cargo test
prltc ls src/
prltc grep "pattern" src/
prltc find "*.rs" .
prltc docker ps
prltc gh pr list
```

## Meta Commands

```bash
prltc gain              # Show token savings
prltc gain --history    # Command history with savings
prltc discover          # Find missed PRLTC opportunities
prltc proxy <cmd>       # Run raw (no filtering, for debugging)
```

## Why

PRLTC filters and compresses command output before it reaches the LLM context, saving 60-90% tokens on common operations. Always use `prltc <cmd>` instead of raw commands.
