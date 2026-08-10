# Shared agent configuration

This directory is the portable global source of truth for Claude Code, Codex, and OpenCode.
Repository-specific guidance belongs in each repository's root `AGENTS.md`; dotfiles development
guidance lives in the root `AGENTS.md` here.

## Canonical surfaces

| Surface | Location | Contract |
|---|---|---|
| Global guidance | `~/.agents/AGENTS.md` | Small, client-neutral defaults |
| Personal skills | `~/.agents/skills/*/SKILL.md` | Agent Skills open standard; loaded on demand |
| Repo guidance | `<repo>/AGENTS.md` | Standard project instructions |

Do not add duplicated client-specific instruction bodies. Claude, Codex, and OpenCode use thin
native adapters around these canonical files because their global discovery paths differ.

## Client adapters

| Client | Global instructions | Skills | Native config |
|---|---|---|---|
| Codex | `~/.codex/AGENTS.md` symlink | Reads `~/.agents/skills` natively | `~/.codex/config.toml` |
| OpenCode | `~/.config/opencode/AGENTS.md` symlink | Reads `~/.agents/skills` natively | `~/.config/opencode/opencode.json` |
| Claude Code | `SessionStart` loads the applicable `AGENTS.md` chain | `~/.claude/skills` symlink | `~/.claude/settings.json` |

Claude Code does not currently discover `AGENTS.md` directly. The SessionStart adapter keeps the
repo free of `CLAUDE.md` files while presenting Claude with the same global and project guidance.
Custom subagents are intentionally not shared: the three clients use incompatible agent formats.
Use Agent Skills for portable reusable workflows.

`OPENCODE_DISABLE_CLAUDE_CODE=1` disables OpenCode's Claude-compatibility fallback. OpenCode still
loads the canonical `AGENTS.md` and `.agents/skills` paths natively, without discovering the Claude
adapter or the same skill IDs twice.

## Token efficiency

- RTK filters shell output. Claude uses its native pre-tool hook, OpenCode uses
  `plugins/rtk.ts`, and Codex follows the global `AGENTS.md` rule.
- Semble is the only configured MCP server. Use it for semantic code discovery, then open the
  returned file and lines directly; use `rg` for exact or exhaustive matches.
- OpenCode enables automatic compaction and old-tool-output pruning.
- Skill bodies and supporting files remain unloaded until a matching skill is selected.

## MCP policy

All three clients are reconciled by `setup.sh` to exactly one global MCP server:

```text
uvx --from semble[mcp]==0.5.4 semble
```

Keep the Semble version pinned across clients so search behavior does not drift between machines.
When updating it, change the mise tool entry, all native MCP configs, and the checks together.
OpenCode authentication uses the ChatGPT browser flow on macOS and its headless flow on Linux.

## Shared hooks

| Script | Purpose |
|---|---|
| `scripts/agent-instructions.sh` | Loads standard global/project `AGENTS.md` files for Claude |
| `scripts/format-on-save.sh` | Formats files after edits |
| `scripts/agent-pane-idle.sh` | Tracks tmux pane state |
| `scripts/agent-pane-title.sh` | Updates compatible terminal pane titles |
