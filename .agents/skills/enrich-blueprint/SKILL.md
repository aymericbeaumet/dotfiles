---
name: enrich-blueprint
description: Propose plan-only improvements to ~/.agents/blueprints from the current project. Use when the user asks to enrich, improve, update, or extract a blueprint, or mentions enrich-blueprint.
---

# Enrich Blueprint

Stay in plan mode until the user confirms which candidates to include. Complete the comparison and
prepare concrete proposed revisions before asking. Honor choices already confirmed in the session;
apply those choices without asking again, and keep unconfirmed candidates as proposals.

## Location

Blueprints live at:

```text
~/.agents/blueprints/<KIND>.md
```

`<KIND>` is an uppercase short name such as `CLI`. Resolve that directory from the home directory.
Do not write blueprints into the current project.

## Task

1. Resolve the current project root. If there is no Git repository, ask which project to inspect.
2. List existing files in `~/.agents/blueprints/`.
3. Survey the current project. Read only what is needed to judge reuse:
   - stack and language manifests
   - CI workflows
   - README
   - direct dependencies
   - license
   - build, test, and release entry points
   - packaging
   - project `AGENTS.md`
4. Choose the matching blueprint, or propose creating a new `<KIND>.md` when none fits.
5. Diff durable project conventions against that blueprint.
6. Classify every candidate:
   - **Keep** — already specified
   - **Add** — reusable and missing
   - **Update** — specified but drifted
   - **Skip** — product-specific, secret, machine-specific, or obvious from the repo
   - **Ask** — reusable value is unclear
7. Present a short plan: target path, concrete proposed adds and updates, and material skips.
8. Ask which candidates to include when the selection has not already been confirmed. Cover the
   relevant surveyed areas and every **Ask** item. Do not assume omitted areas should be copied.
9. Wait for selection before changing unconfirmed candidates. If the user has already confirmed
   choices, apply only those revisions and check the resulting diff against the selection.

## Include only when

- The convention is stable and would help start or align another repo of the same kind.
- It is not recoverable by reading a typical repository of that stack.
- It is not product behavior, a secret, or a one-off workaround.

## Output

Lead with the target blueprint path. For a proposal, list Add / Update / Skip / Ask and end with the
remaining selection question. After applying confirmed choices, summarize the revisions and any
unresolved candidates.
