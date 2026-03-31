# PRLTC - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use prltc directly)

```bash
prltc gain              # Show token savings analytics
prltc gain --history    # Show command usage history with savings
prltc discover          # Analyze Claude Code history for missed opportunities
prltc proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
prltc --version         # Should show: prltc X.Y.Z
prltc gain              # Should work (not "command not found")
which prltc             # Verify correct binary
```

⚠️ **Name collision**: If `prltc gain` fails, you may have reachingforthejack/prltc (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `prltc git status` (transparent, 0 tokens overhead)

Refer to CLAUDE.md for full command reference.
