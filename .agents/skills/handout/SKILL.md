---
name: handout
description: Create or load a local repository handout so another agent can resume active work. Use with no identifier to save the current context under a generated ID, or with an identifier to load that handout and continue.
---

# Handout

Choose the mode only from whether the user supplied an identifier:

- No identifier: create mode.
- Identifier supplied: load mode.

## Location

Resolve the current Git repository root. If there is no repository, ask which repository should own
the handout. Store every artifact at:

```text
<repository-root>/.handouts/<id>.md
```

Never accept an identifier that resolves outside `.handouts`.

## Identifiers

In create mode, the ID MUST use this form:

```text
<UTC YYYYMMDD-HHMM>-<short-topic-slug>
```

Derive the lowercase ASCII slug from the active objective, using at most five meaningful words.
Remove path separators and unsafe characters, collapse repeated hyphens, and append `-2`, `-3`, and
so on if the path already exists. Never use a UUID, random value, hash, or identifier supplied by
the user in create mode.

In load mode, normalize only a trailing `.md`; otherwise use the supplied ID exactly after rejecting
path separators, an empty value, `.` and `..`.

## Create Mode

1. Gather the active objective, user requirements, decisions and rationale, completed work,
   unresolved work, failures, verification, and intended next action.
2. Inspect live state that a fresh agent cannot recover from conversation alone: repository root,
   branch, HEAD, worktree status, relevant diff summary, and important untracked files.
3. Write `.handouts/<id>.md` with the structure below. Use absolute dates and paths where ambiguity
   would hurt resumption.
4. Keep the handout local. Never stage or commit handouts; `.handouts/` is globally ignored.
5. Report the generated ID first, followed by the path and the portable instruction `/handout <id>`.

```markdown
# Handout: <id>

> Resume: verify live state, then continue from **Next Actions**.

- Updated: <ISO 8601 timestamp>
- Working directory: `<absolute path>`
- Repository: `<root>`
- Branch: `<branch>`
- HEAD: `<commit>`
- Source session: `<native session identifier when readily available>`

## Objective

<desired end state and why it matters>

## User Requirements

- <explicit constraints, preferences, and acceptance criteria>

## Current State

<what works, what is in progress, and the exact boundary of unfinished work>

## Decisions

- <decision and rationale; include rejected alternatives only when useful>

## Work Completed

- <change or investigation, with paths, symbols, commits, or URLs>

## Key Locations

- `<path[:line]>`: <why the next agent needs it>

## Verification

- Passed: `<command>` - <result>
- Not run: `<command>` - <reason>

## Remaining Work

- <specific unfinished item and definition of done>

## Blockers and Risks

- <blocker, uncertainty, stale assumption, or sensitive edge case>

## Next Actions

1. <first concrete action>
2. <subsequent action>

## Suggested Skills

- `<skill>`: <why it applies>
```

Omit empty sections. Capture enough reasoning to prevent repeated investigation, but reference
existing plans, specs, diffs, issues, and commits instead of duplicating them. Distinguish
user-authored changes from agent-authored changes when known. Never claim a test passed unless it
ran successfully.

Redact secrets, tokens, credentials, private keys, sensitive environment values, and unnecessary
personal information. Do not reproduce secret-like strings even when they appeared in the
conversation or diff.

## Load Mode

1. Read the complete `.handouts/<id>.md`. If it does not exist, list available IDs and ask which one
   to load; do not guess.
2. Read the applicable `AGENTS.md` chain and inspect the handout's declared working directory and
   current repository state.
3. Treat the handout as navigation rather than authority. Reconcile its branch, HEAD, worktree,
   files, and completed items with live state, and call out material drift.
4. Continue from **Next Actions** unless the user asked only for a summary. Do not rewrite the
   handout or repeat its contents before acting unless state reconciliation requires an update.
