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
  checkout, unless the repository's `AGENTS.md` designates direct work on its default branch; then
  stay in that checkout and skip the handoff. Before switching directories, capture the source
  branch, HEAD, upstream, and pending work, then follow the bonsai skill's existing-work handoff.
  Preserve that source state and the configured push destination, which may differ from the
  upstream. Do not wait for confirmation to create the worktree or run the requested workflow.
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
  and reusable lessons that improve future work. Integrate these directly into the narrowest
  applicable `AGENTS.md` as part of normal work, without waiting to be asked.
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
- Guidance files load on every turn, so keep them short and unconditional. Instructions that apply
  only to a specific task belong in a skill, which is loaded on demand.

## Token-efficient shell use

- Prefix every shell command with `rtk`.
- Prefer RTK's native wrappers for Git, GitHub, tests, builds, package managers, file reads, and
  searches. Use `rtk proxy <command>` only when exact unfiltered output is required.
- If RTK reports a saved full-output path after a failure, inspect that file instead of rerunning
  the noisy command.
- Read files in bounded ranges. Beyond roughly 200 lines, pass an explicit offset and limit and
  take the window around the symbol you need. Widen only when the target is not in range;
  slurping a whole file is the exception, not the default.
- Bound every search. Cap match output with `| head -50`, and prefer line-numbered matches
  (`rg -n`) or file lists (`rg -l`) over dumping every hit. Narrow the pattern or path before
  raising the cap, so large repositories never tokenize a haystack nobody reads.
- Filter verbose command output at the source. Pipe test, build, and log runs through the failing
  lines you actually need; tool output stays in context for the rest of the session, so a noisy
  run is paid for on every later turn, not just once.
- Prefer a purpose-built CLI over an equivalent MCP server when both expose the same capability.

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
- Delegate to protect the main context, not only to parallelize. A search that would dump many
  files into this window belongs in a subagent that returns the conclusion and its `file:line`
  references. Ask for a bounded report rather than raw excerpts.
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

## Local containers

- Default to Colima with Docker on macOS; use native Docker Engine on Linux. On Apple Silicon,
  prefer Apple's VZ virtualization, virtiofs mounts, and Rosetta for required amd64 images.
- Inspect the current Docker context and Colima status before starting or changing a runtime.
  Respect explicit remote contexts. Derive socket paths from the selected context; do not force
  `DOCKER_HOST` globally or replace `/var/run/docker.sock` with a symlink.
- Preserve existing profiles, named volumes, and databases. VM deletion, volume pruning, and
  `docker compose down --volumes` require explicit authorization for the affected data; they are
  not routine troubleshooting or cache cleanup.
