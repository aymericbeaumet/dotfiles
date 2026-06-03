# Shared agent rig

Single source of truth for Claude Code and Codex configuration. Both harnesses load skills, subagents, hook scripts, and memory conventions from here.

## Layout

```
~/.dotfiles/.agents/
  AGENTS.md          # auto-loaded every session by both harnesses; keep small
  RTK.md             # auto-loaded via AGENTS.md @import; rtk prefix rule
  agents/            # subagents (Anthropic frontmatter spec)
    code-reviewer.md
    test-runner.md
    security-auditor.md
    rust-clippy-fixer.md      # isolation: worktree
    dep-upgrader.md           # isolation: worktree
    doc-writer.md
  skills/            # SKILL.md instruction packs
    commit/          # disallows Edit/Write/MultiEdit
    distill/         # Codex-style task-group memory
    pr/              # disallows Edit/Write/MultiEdit
    push/            # needs Edit for rebase conflict resolution
    squash/          # disallows Edit/Write/MultiEdit
    peon-ping-*/     # peon trainer integrations
    .system/         # Codex-installed system skills (auto-managed)
  memories/          # Codex's rich rollout→MEMORY pipeline; Claude uses
                     # ~/.claude/projects/<cwd-slug>/memory/ instead
```

## Symlinks

| From | To |
|---|---|
| `~/.claude/CLAUDE.md` | `../.agents/AGENTS.md` |
| `~/.claude/skills` | `../.agents/skills` |
| `~/.claude/agents` | `../.agents/agents` |
| `~/.codex/AGENTS.md` | `../.agents/AGENTS.md` |
| `~/.codex/skills` | `../.agents/skills` |
| `~/.codex/agents` | `../.agents/agents` |

## Shared scripts (used by both harnesses)

| Script | Purpose |
|---|---|
| `~/.dotfiles/scripts/format-on-save.sh` | PostToolUse formatter (rustfmt/gofmt/prettier/ruff/shfmt/taplo/stylua/nixpkgs-fmt/sqlfluff) |
| `~/.dotfiles/scripts/agent-pane-idle.sh` | tmux pane border state — `clear`/`busy`/`idle` |
| `~/.dotfiles/scripts/agent-pane-title.sh` | tmux pane title from session JSON (Codex; Claude uses statusline) |
| `~/.claude/hooks/peon-ping/peon.sh` | peon-ping sound (Claude direct) |
| `~/.claude/hooks/peon-ping/codex-hook.sh <event>` | peon-ping with Codex event-name wrapping |

## Hook lifecycle parity

| Event | Claude | Codex | Notes |
|---|---|---|---|
| PreToolUse(Bash) | ✓ rtk | — | `rtk hook` supports claude/cursor/gemini/copilot only — use rtk prefix manually on Codex |
| PostToolUse Edit\|Write\|MultiEdit\|apply_patch | ✓ format-on-save | ✓ format-on-save | Shared script |
| PostToolUse(Bash) | — | ✓ peon-ping | Codex variant; Claude uses PostToolUseFailure |
| SessionStart | ✓ peon + idle clear | ✓ peon + idle clear | |
| SessionEnd | ✓ peon | — | Not supported by Codex; use Stop |
| UserPromptSubmit | ✓ peon + idle busy | ✓ peon + idle busy | |
| Stop | ✓ peon + idle idle | ✓ peon + idle idle + pane-title | Codex sets pane title (Claude uses statusline) |
| SubagentStart | ✓ peon | ✓ peon | |
| SubagentStop | ✓ peon | ✓ peon | |
| PermissionRequest | ✓ peon | ✓ peon | |
| Notification | ✓ peon | — | Codex has no Notification hook |
| PostToolUseFailure(Bash) | ✓ peon | — | Codex's PostToolUse fires on non-zero exit |
| PreCompact | ✓ peon | ✓ peon | |
| PostCompact | ✓ peon | ✓ peon | |

## MCP parity

| Server | Claude | Codex |
|---|---|---|
| `tmux` (`npx -y tmux-mcp --shell-type=zsh`) | ✓ | ✓ |
| `semble` (`uvx --from semble[mcp] semble`) | ✓ | ✓ |
| 14 cloud connectors (Linear, Notion, Gmail, …) | ✓ configured (OAuth needed) | — |

Claude MCP servers are managed by `claude mcp add/remove`. Codex MCP servers live in `[mcp_servers.X]` blocks of `~/.codex/config.toml`.

## Plugin marketplaces

| Marketplace | Claude | Codex |
|---|---|---|
| `anthropics/claude-plugins-official` | ✓ | — (Claude-only format) |
| `wshobson/agents` (aka `claude-code-workflows`) | ✓ | ✓ (multi-harness) |
| `openai-curated` | — | ✓ (built-in) |

Add with `claude plugin marketplace add <owner>/<repo>` or `codex plugin marketplace add <owner>/<repo>`.

## Skill / subagent / memory format notes

- Skill frontmatter uses **kebab-case** keys (`disallowed-tools`, `allowed-tools`).
- Subagent frontmatter uses **camelCase** keys (`disallowedTools`, `permissionMode`).
- Codex memory: `~/.codex/memories/MEMORY.md` (rich task-group format the `distill` skill produces).
- Claude memory: per-project `~/.claude/projects/<cwd-slug>/memory/<name>.md` files indexed by `MEMORY.md`.

## Effort / sandbox / approval posture

| Setting | Claude | Codex |
|---|---|---|
| Default effort | `high` (`effortLevel` in settings.json) | `xhigh` (`model_reasoning_effort`) |
| Plan-mode effort | inherits | `xhigh` (`plan_mode_reasoning_effort`) |
| Permission mode | `auto` (`defaultMode`) | `on-request` (`approval_policy`) |
| Sandbox | implicit (per-tool permissions) | `danger-full-access` (`sandbox_mode`) |
| Skip auto perm prompt | ✓ (`skipAutoPermissionPrompt`) | implicit |

## Adding new things

- **New skill**: create `~/.dotfiles/.agents/skills/<name>/SKILL.md`; both harnesses pick it up immediately (Claude via `/reload-skills`, Codex on restart).
- **New subagent**: create `~/.dotfiles/.agents/agents/<name>.md`; Claude loads on next session.
- **New hook event**: add to both `~/.claude/settings.json` (JSON) and `~/.dotfiles/.codex/config.toml` (TOML). Codex will prompt to trust on first run.
- **New MCP server**: `claude mcp add` for Claude; add `[mcp_servers.<n>]` block to `config.toml` for Codex.
