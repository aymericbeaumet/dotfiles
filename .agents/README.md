# Shared agent configuration

This directory is the portable global source of truth for Claude Code and Codex.
Repository-specific guidance belongs in each repository's root `AGENTS.md`; dotfiles development
guidance lives in the root `AGENTS.md` here.

## Canonical surfaces

| Surface | Location | Contract |
|---|---|---|
| Global guidance | `~/.agents/AGENTS.md` | Small, client-neutral defaults |
| Personal skills | `~/.agents/skills/*/SKILL.md` | Agent Skills open standard; loaded on demand |
| Repo guidance | `<repo>/AGENTS.md` | Distilled project instructions for agents |
| Project documentation | `<repo>/docs/` | Documentation and context for humans and agents |
| Work handouts | `<repo>/.handouts/<id>.md` | Local session-resumption snapshots |
| Project blueprints | `~/.agents/blueprints/` | Reusable specs for new repos (not loaded automatically) |

Do not add duplicated client-specific instruction bodies. Each client uses a thin native adapter
around these canonical files because its global discovery paths differ.

The rationale and review boundaries for shared behavior updates are recorded in
[`docs/agent-guidance.md`](../docs/agent-guidance.md).

## Client adapters

| Client | Global instructions | Skills |
|---|---|---|
| Codex | `~/.codex/AGENTS.md` symlink | Reads `~/.agents/skills` natively |
| Claude Code | `SessionStart` loads the `AGENTS.md` chain | `~/.claude/skills` symlink |

Claude Code does not currently discover `AGENTS.md` directly. The SessionStart adapter keeps the
repo free of `CLAUDE.md` files while presenting Claude with the same global and project guidance.

## Portable continuity

- Each project's `AGENTS.md` and committed `docs/` evolve through normal work and corrections.
  `AGENTS.md` receives distilled instructions for agents; `docs/` holds documentation, rationale,
  and context for humans and agents. Relevant content is read before related work and updated when
  durable lessons emerge, without a separate request or client-specific injection adapter.
- Claude and Codex native auto-memory are disabled so new project knowledge cannot fork into local,
  client-only stores. Existing native memory files remain untouched as archives.
- `handout` writes an ignored local `.handouts/<id>.md` snapshot for active work. Invoking it without
  an ID creates one; invoking it with an ID loads that snapshot.
- `blueprint` compares the current project to `~/.agents/blueprints/` and asks what to
  include. It stays in plan mode until the user confirms.
- Project memory and distilled `AGENTS.md` guidance follow the repository's normal version-control
  policy. Handouts remain ignored, transient working state.
- Claude Code exposes `/handout` and `/blueprint`. Codex exposes the same shared skills as
  `$handout` and `$blueprint`.
- Shared atomic Git workflow skills are `commit`, `push`, and `squash`. Slash-separated requests
  compose them in order and stop on the first failure. `commit`, `push`, and `pullrequest` always
  run inside a bonsai worktree without waiting for confirmation to create it. Before a checkout
  handoff, capture the source branch, commits, pending changes, and intended push destination;
  follow the bonsai skill to preserve them.
- `pullrequest` is the one-shot PR workflow: prepare and publish the branch, create or update the PR,
  merge the actual base, fix or answer review feedback, repair actionable CI failures, and repeat
  until the PR is ready to merge.
Custom subagents are intentionally not shared: the clients use incompatible agent formats.
Use Agent Skills for portable reusable workflows.

## Codex hook trust

Codex hook trust is machine- and path-specific. `setup.sh` uses Codex's `hooks/list` and
`config/batchWrite` app-server APIs to remove an inline hook event only when every old handler has a
normalized-hash match in tracked `~/.codex/hooks.json`. It preserves unrelated inline hooks and all
other user configuration, then verifies that every tracked hook is enabled and trusted.

## Token efficiency

- RTK filters shell output. Claude uses its native pre-tool hook, and Codex follows the global
  `AGENTS.md` rule.
- Semble is the only configured MCP server. Use it for semantic code discovery, then open the
  returned file and lines directly; use `rg` for exact or exhaustive matches.
- Skill bodies and supporting files remain unloaded until a matching skill is selected.

## Formatting and failure recovery

- Project formatter configuration, editor formatting, and the project's required checks own
  formatting. Global agent hooks do not rewrite files after individual edits.
- Claude enables its supported retry watchdog. A terminal failure that escapes native retries
  requires an explicit continuation; no hook injects input into tmux.
- Codex keeps its native request/stream retries and goals without terminal-error input injection.

## MCP policy

Both clients are reconciled by `setup.sh` to exactly one global MCP server: Semble. Mise manages the
CLI through uv; MCP uses a separate cached `uvx --from semble[mcp]==0.5.4 semble` environment for its
MCP dependencies. Keep their versions pinned together on both machines. When updating Semble,
change the mise tool entry, native MCP configuration, and checks together.

## Shared hooks

| Script | Purpose |
|---|---|
| `scripts/agent-instructions.sh` | Loads standard global/project `AGENTS.md` files for Claude |
| `scripts/configure-codex-hooks.mjs` | Migrates mirrored inline Codex hooks and records native trust |
| `scripts/agent-pane-idle.sh` | Tracks tmux pane state |
| `scripts/agent-pane-title.sh` | Updates compatible terminal pane titles |
| `scripts/worktree-guard.sh` | Enforces the shared bonsai worktree workflow |
