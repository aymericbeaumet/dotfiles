---
name: distill
description: Distill the current session into a rich, scoped memory entry — for Codex sessions, append to ~/.codex/memories/rollout_summaries/ in the established task-group format; for Claude sessions, write to the auto-memory directory. Use when you've finished a non-trivial unit of work that future-you (or another agent) should benefit from.
allowed-tools: Bash, Read, Write, Glob, Grep
---

## Why this exists

Both Claude Code and Codex have built-in memory, but Codex's `~/.codex/memories/MEMORY.md` follows a richer pattern than Claude's default auto-memory: scoped task groups with explicit `applies_to` / `reuse_rule`, user preferences with citations, reusable knowledge as bulleted facts, and "failures and how to do differently" sections. This skill produces that shape on demand, regardless of which harness you're in.

## Task

1. **Identify session context**:
   - Current working directory: `pwd`
   - Branch and recent commits: `git rev-parse --abbrev-ref HEAD && git log --oneline -10`
   - Detect harness from environment: if `$CLAUDE_PROJECT_DIR` set → Claude; if `$CODEX_HOME` set → Codex. Default to Claude when ambiguous.

2. **Identify what's worth distilling** (skip if none apply):
   - User preferences expressed during the session ("I prefer X over Y", corrections to your earlier behavior)
   - Reusable knowledge about this checkout (file locations, build commands, conventions that aren't obvious from the code)
   - Failures and recoveries (something didn't work, here's what did)
   - Non-obvious gotchas worth flagging next time

   If nothing meets the bar, report "nothing material to distill" and stop. Over-saving is worse than under-saving.

3. **Write the entry** in this exact shape, appended to the appropriate target file:

   ```markdown
   # Task Group: <cwd> <short topic>

   scope: <one sentence on what this group covers>
   applies_to: cwd=<cwd>; reuse_rule=<checkout-specific|broadly-reusable> for <reason>

   ## Task <N>: <short title>, <success|partial|failed>

   ### keywords

   - <comma-separated retrieval anchors>

   ## User preferences

   - when <situation>, the user <preference quote or paraphrase> -> <how to apply next time>. [Task <N>]

   ## Reusable knowledge

   - <fact about this checkout>. [Task <N>]

   ## Failures and how to do differently

   - Symptom: <what went wrong>. Cause: <root cause>. Fix: <what to do next time>. [Task <N>]
   ```

   Sections may be omitted if they have no content for this distillation.

4. **Target file selection**:
   - **Codex**: append to `~/.codex/memories/MEMORY.md` (or create a per-session rollout summary at `~/.codex/memories/rollout_summaries/$(date -u +%Y-%m-%dT%H-%M-%S)-<slug>.md` and link from `MEMORY.md`).
   - **Claude**: write under `~/.claude/projects/$(pwd | sed 's|/|-|g')/memory/` as individual `<slug>.md` files using the auto-memory frontmatter format (see `~/.claude/CLAUDE.md`), and add one-line entries to that project's `MEMORY.md` index.

5. **Convert relative dates** in the content to absolute dates (`Thursday` → `2026-MM-DD`).

6. **Report**: which file you wrote to, how many entries, and one-sentence summary of each.

## Constraints

- Do not save code patterns, conventions, or file paths that can be derived by reading the project — those rot. Save WHY and HOW-NEXT-TIME, not WHAT-EXISTS.
- Do not save in-progress work or current-conversation state — those belong in a plan or task list, not memory.
- Update or remove existing entries that this session contradicted rather than stacking conflicting facts.
