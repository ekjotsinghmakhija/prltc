# PRLTC Plugin for OpenClaw

Transparently rewrites shell commands executed via OpenClaw's `exec` tool to their PRLTC equivalents, achieving 60-90% LLM token savings.

This is the OpenClaw equivalent of the Claude Code hooks in `hooks/prltc-rewrite.sh`.

## How it works

The plugin registers a `before_tool_call` hook that intercepts `exec` tool calls. When the agent runs a command like `git status`, the plugin delegates to `prltc rewrite` which returns the optimized command (e.g. `prltc git status`). The compressed output enters the agent's context window, saving tokens.

All rewrite logic lives in PRLTC itself (`prltc rewrite`). This plugin is a thin delegate -- when new filters are added to PRLTC, the plugin picks them up automatically with zero changes.

## Installation

### Prerequisites

PRLTC must be installed and available in `$PATH`:

```bash
brew install prltc
# or
curl -fsSL https://raw.githubusercontent.com/ekjotsinghmakhija/prltc/refs/heads/master/install.sh | sh
```

### Install the plugin

```bash
# Copy the plugin to OpenClaw's extensions directory
mkdir -p ~/.openclaw/extensions/prltc-rewrite
cp openclaw/index.ts openclaw/openclaw.plugin.json ~/.openclaw/extensions/prltc-rewrite/

# Restart the gateway
openclaw gateway restart
```

### Or install via OpenClaw CLI

```bash
openclaw plugins install ./openclaw
```

## Configuration

In `openclaw.json`:

```json5
{
  plugins: {
    entries: {
      "prltc-rewrite": {
        enabled: true,
        config: {
          enabled: true,    // Toggle rewriting on/off
          verbose: false     // Log rewrites to console
        }
      }
    }
  }
}
```

## What gets rewritten

Everything that `prltc rewrite` supports (30+ commands). See the [full command list](https://github.com/ekjotsinghmakhija/prltc#commands).

## What's NOT rewritten

Handled by `prltc rewrite` guards:
- Commands already using `prltc`
- Piped commands (`|`, `&&`, `;`)
- Heredocs (`<<`)
- Commands without an PRLTC filter

## Measured savings

| Command | Token savings |
|---------|--------------|
| `git log --stat` | 87% |
| `ls -la` | 78% |
| `git status` | 66% |
| `grep` (single file) | 52% |
| `find -name` | 48% |

## License

MIT -- same as PRLTC.
