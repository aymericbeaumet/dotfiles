# Shared agent defaults

These defaults apply across repositories and clients. A repository's own `AGENTS.md` adds the
project-specific commands and constraints.

## Follow-through and authorization

- Treat action requests as work to complete. Infer routine choices from context and continue until
  the requested outcome is verified or a concrete blocker remains.
- Carry prior authorization forward within its scope. Ask only when missing information changes
  the result materially and cannot be inferred, or the next action lacks authorization. Complete
  independent, authorized preparation before asking for approval of a reviewable result.
- User instructions override skill defaults. Before treating a file's rule as a blocker, check its
  scope and the user's existing authorization. If it still blocks work, link the exact file, quote
  the rule, and explain what remains blocked; distinguish the rule from your interpretation.
- Treat mid-task corrections and questions as updates to the active task. Answer side questions,
  incorporate new constraints, and resume unless the user cancels or replaces the objective.

## Communication

- Lead with the outcome or intended action in concise, plain prose. Use lists and tables when they
  make the information easier to follow; avoid stock phrases, invented jargon, and repeated summaries.
- During longer work, give brief updates on findings and the next useful step. Finish with what
  changed, relevant verification, and any unresolved limits, scaled to the task.

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

- Proactively maintain each project's `AGENTS.md` and `./docs` over time. After non-trivial work or
  corrections, distill durable lessons into the appropriate surface and update or remove stale
  content. Leave them unchanged when there is nothing material to preserve.
- Keep the applicable `AGENTS.md` chain concise and actionable for agents: workflows, constraints,
  and reusable lessons that improve future work. Use the `distill` skill to integrate these into
  the narrowest applicable `AGENTS.md` as part of normal work, without waiting to be asked.
- Use the project's `docs/` directory for documentation and context shared by humans and agents:
  architecture, decisions and rationale, usage, operations, and durable project knowledge. Read
  relevant documents before related work and keep them concise, descriptively named, and current.
- Project memory must live directly inside the repository it describes and be committed so every
  contributor and client shares the same context. Never use `MEMORY.md`, `.memories/`, symlinked
  memory paths, external shared memory trees, or client-specific memory or state directories.
- Keep unfinished work and session-resumption details in `.handouts/`, not in `docs/` or
  `AGENTS.md`; handouts are transient context, not project memory.
- Distill instructions into `AGENTS.md` and explanations into `./docs`; link relevant documents
  instead of duplicating them. Exclude secrets, session logs, and incidental history from both.

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

- When delegation is available and independent, non-trivial work would benefit from parallelism,
  launch suitable subagents together while continuing useful local work.
- Give each subagent a disjoint scope, complete context, expected output, and verification needs.
- Write legible inter-agent messages with normal spacing; they may be read by the user.
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
- Match verification to the changed behavior and run the repository's required checks. Avoid tests
  that merely restate implementation or prose. After checks pass, repeat or expand them only for
  further changes, failures, or a specific unresolved concern.
- Add comments only when the why is not obvious from names and structure. Prefer a clear idiom over
  a comment that restates the code.
