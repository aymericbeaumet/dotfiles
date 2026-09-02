# Shared agent defaults

These defaults apply across repositories and clients. A repository's own `AGENTS.md` adds the
project-specific commands and constraints.

## Git branches

- Name every branch you create `ab/<slug>`, using a short lowercase kebab-case slug.

## Git worktrees

- `bonsai` is the only tool for the worktree lifecycle: create, list, jump, remove, clean. Never
  run `git worktree` directly, and never use a harness-native worktree feature (Claude Code
  `EnterWorktree` or agent `isolation: "worktree"`, Cursor worktrees, Codex cloud environments).
- Create or reuse a worktree with `path=$(bonsai add <branch>)`; the command is idempotent, prints
  the worktree's absolute path, and pre-provisions local config. Run all subsequent work inside
  that directory.
- Always run `commit`, `push`, and `pullrequest` from a bonsai worktree, never from the primary
  checkout. If the current directory is not already one, create or reuse `path=$(bonsai add ab/<slug>)`
  and continue there. Do not wait for confirmation to create that worktree or to run the requested
  workflow.
- Worktrees live at `~/.bonsai/<repo-id>/<branch>` regardless of client, so any harness resumes a
  task by opening the same path. Use the `handout` skill to pass in-progress context across
  clients.
- Load the `bonsai` skill before any non-trivial worktree operation.

## Git workflows

- Treat slash-separated Git workflow names in a user request as an ordered pipeline of the matching
  skills. For example, `commit/push` means run `commit`, then `push`.
- Re-inspect repository state between pipeline stages. Stop immediately when a stage fails or needs
  user input; do not continue with later stages.
- Do not infer omitted workflow stages. The `pullrequest` skill is explicitly end-to-end: invoke it
  once and let it create commits, publish the branch, create or update the PR, and converge review
  and CI based on live state.
- Never add `Co-Authored-By`, `Made-with`, `Generated-by`, "Generated with …", or any other agent or
  harness attribution in commits, pull requests, comments, or files. Leave no trace that a tool
  authored the work.

## Project continuity

- Treat `.memories/MEMORY.md` as the canonical local project memory shared by every client.
  Maintain it proactively after non-trivial work when concise, non-secret, non-obvious project
  knowledge would materially help future sessions; otherwise leave it unchanged.
- Treat the applicable `AGENTS.md` chain as committed project guidance, not as a session log or a
  substitute for shared project memory.
- Use the `distill` skill when asked to integrate durable, reusable lessons into the narrowest
  applicable `AGENTS.md`.
- Keep unfinished work and session-resumption details in `.handouts/`, not in `.memories/` or
  `AGENTS.md`.
- Do not copy memory into handouts or distill it into `AGENTS.md` automatically; each surface has a
  separate lifecycle.
- Never save project memory in a client-specific memory or state directory.

## Token-efficient shell use

- Prefix every shell command with `rtk`.
- Prefer RTK's native wrappers for Git, GitHub, tests, builds, package managers, file reads, and
  searches. Use `rtk proxy <command>` only when exact unfiltered output is required.
- If RTK reports a saved full-output path after a failure, inspect that file instead of rerunning
  the noisy command.

## Code discovery

- Start unfamiliar behavior, architecture, or symbol discovery with Semble's `search` tool.
- Use `find_related` from a promising result when the relationship is semantic rather than a
  literal reference.
- Open the returned file at the returned lines; do not immediately repeat the same discovery with
  grep or broad file reads.
- For prose or configuration discovery, use
  `rtk proxy semble search --content docs config --max-snippet-lines 10 "<query>" <path>`.
- Use `rg` for exact strings, filenames, and exhaustive caller/reference searches.

## Parallel delegation

- When two or more non-trivial workstreams are independent, launch all suitable subagents in one
  assistant message so they execute concurrently.
- Give each subagent a disjoint scope, complete context, expected output, and verification needs.
- Do not duplicate delegated work. Wait for all relevant results before integrating them.
- Parallelize edits only when agents own disjoint files; otherwise parallelize research and keep
  integration serial.
- Do not delegate trivial reads, exact-string searches, or work involving only one or two known
  files.

## Implementation

- Prefer pure functions and a functional style when they make behavior easier to test and change:
  explicit inputs and outputs, no hidden mutation, composition over shared mutable state.
- Model multi-step or event-driven logic as an explicit state machine when the transitions matter;
  do not hide them in ad-hoc flags and nested conditionals.
- Use TDD when the behavior is non-trivial and testable: pin the contract with a failing test, then
  implement. Skip the ceremony for trivial glue.
- Add comments only when the why is not obvious from names and structure. Prefer a clear idiom over
  a comment that restates the code.
