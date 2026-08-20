---
name: distill
description: Distill durable, reusable lessons from completed work into the applicable AGENTS.md. Use after a non-trivial task or correction reveals a stable instruction that future agents should follow.
---

# Distill

1. Identify lessons that are durable, actionable, non-obvious, and likely to prevent future
   mistakes.
2. Stop with `nothing material to distill` if the session contains only transient state, facts
   recoverable from the repository, or unfinished work.
3. Resolve the repository root and read the applicable `AGENTS.md` chain from the root toward the
   affected files.
4. Put repository-wide guidance in the root `AGENTS.md`. Put subtree-specific guidance in the
   narrowest applicable nested `AGENTS.md`.
5. If no suitable file exists, create a root `AGENTS.md` only for a clearly durable repository-wide
   lesson.
6. Integrate each lesson as a concise imperative rule under the most relevant existing section.
   Update or remove contradicted guidance instead of appending history.
7. Report the file changed and summarize each durable rule added or updated.

## Constraints

- Save instructions and rationale, not session history, task logs, citations, timestamps, or current
  work state.
- Do not save conventions or paths that are obvious from reading the repository.
- Do not duplicate guidance already present in the applicable `AGENTS.md` chain.
- Do not write durable lessons to a client-specific memory or state directory.
- Preserve unrelated content and follow the repository's existing organization and style.
- For cross-repository personal guidance, use a canonical global `AGENTS.md` only when its location
  is established by the current environment; otherwise ask.
