# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `rtk`.

Examples:

```bash
rtk git status
rtk cargo test
rtk npm run build
rtk pytest -q
```

## Meta Commands

```bash
rtk gain            # Token savings analytics
rtk gain --history  # Recent command savings history
rtk proxy <cmd>     # Run raw command without filtering
```

## Tool Notes

Claude may also rewrite Bash commands through `rtk hook claude`, but shared agent guidance should still prefer explicit `rtk` prefixes.

## Verification

```bash
rtk --version
rtk gain
which rtk
```
