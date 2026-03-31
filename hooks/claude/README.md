# Claude Code Hooks

> Part of [`hooks/`](../README.md) — see also [`src/hooks/`](../../src/hooks/README.md) for installation code

## Specifics

- Shell-based `PreToolUse` hook -- requires `jq` for JSON parsing
- Returns `updatedInput` JSON for transparent command rewrite (agent doesn't know PRLTC is involved)
- Exits silently (exit 0) on any failure: jq missing, prltc missing, prltc too old (< 0.23.0), no match
- Version guard checks `prltc --version` against minimum 0.23.0
- `prltc-awareness.md` is a slim 10-line instructions file embedded into CLAUDE.md by `prltc init`

## Testing

```bash
# Run the full test suite (60+ assertions)
bash hooks/test-prltc-rewrite.sh

# Test against a specific hook path
HOOK=/path/to/prltc-rewrite.sh bash hooks/test-prltc-rewrite.sh

# Enable audit logging during testing
PRLTC_HOOK_AUDIT=1 PRLTC_AUDIT_DIR=/tmp bash hooks/test-prltc-rewrite.sh
```
