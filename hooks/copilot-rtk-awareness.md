# PRLTC — Copilot Integration (VS Code Copilot Chat + Copilot CLI)

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## What's automatic

The `.github/copilot-instructions.md` file is loaded at session start by both Copilot CLI and VS Code Copilot Chat.
It instructs Copilot to prefix commands with `prltc` automatically.

The `.github/hooks/prltc-rewrite.json` hook adds a `PreToolUse` safety net via `prltc hook` —
a cross-platform Rust binary that intercepts raw bash tool calls and rewrites them.
No shell scripts, no `jq` dependency, works on Windows natively.

## Meta commands (always use directly)

```bash
prltc gain              # Token savings dashboard for this session
prltc gain --history    # Per-command history with savings %
prltc discover          # Scan session history for missed prltc opportunities
prltc proxy <cmd>       # Run raw (no filtering) but still track it
```

## Installation verification

```bash
prltc --version   # Should print: prltc X.Y.Z
prltc gain        # Should show a dashboard (not "command not found")
which prltc       # Verify correct binary path
```

> ⚠️ **Name collision**: If `prltc gain` fails, you may have `reachingforthejack/prltc`
> (Rust Type Kit) installed instead. Check `which prltc` and reinstall from ekjotsinghmakhija/prltc.

## How the hook works

`prltc hook` reads `PreToolUse` JSON from stdin, detects the agent format, and responds appropriately:

**VS Code Copilot Chat** (supports `updatedInput` — transparent rewrite, no denial):
1. Agent runs `git status` → `prltc hook` intercepts via `PreToolUse`
2. `prltc hook` detects VS Code format (`tool_name`/`tool_input` keys)
3. Returns `hookSpecificOutput.updatedInput.command = "prltc git status"`
4. Agent runs the rewritten command silently — no denial, no retry

**GitHub Copilot CLI** (deny-with-suggestion — CLI ignores `updatedInput` today, see [issue #2013](https://github.com/github/copilot-cli/issues/2013)):
1. Agent runs `git status` → `prltc hook` intercepts via `PreToolUse`
2. `prltc hook` detects Copilot CLI format (`toolName`/`toolArgs` keys)
3. Returns `permissionDecision: deny` with reason: `"Token savings: use 'prltc git status' instead"`
4. Copilot reads the reason and re-runs `prltc git status`

When Copilot CLI adds `updatedInput` support, only `prltc hook` needs updating — no config changes.

## Integration comparison

| Tool                  | Mechanism                               | Hook output              | File                               |
|-----------------------|-----------------------------------------|--------------------------|------------------------------------|
| Claude Code           | `PreToolUse` hook with `updatedInput`   | Transparent rewrite      | `hooks/prltc-rewrite.sh`             |
| VS Code Copilot Chat  | `PreToolUse` hook with `updatedInput`   | Transparent rewrite      | `.github/hooks/prltc-rewrite.json`   |
| GitHub Copilot CLI    | `PreToolUse` deny-with-suggestion       | Denial + retry           | `.github/hooks/prltc-rewrite.json`   |
| OpenCode              | Plugin `tool.execute.before`            | Transparent rewrite      | `hooks/opencode-prltc.ts`            |
| (any)                 | Custom instructions                     | Prompt-level guidance    | `.github/copilot-instructions.md`  |
