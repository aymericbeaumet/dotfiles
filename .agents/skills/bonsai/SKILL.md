---
name: bonsai
description: Manage git worktrees with the bonsai CLI - create isolated per-branch worktrees outside the repo, jump between them, and clean up merged ones. Use when working on a branch in isolation, parallelizing tasks across worktrees, or tidying up worktrees and branches.
---

# bonsai — centralized git worktrees

## Mental model

- Worktrees live outside the repository at `<root>/<repo-id>/<branch>`
  (default root `~/.bonsai`). Branch names nest: `feat/x` → `feat/x/`.
- Run bonsai from anywhere inside the repo — the main checkout or any
  worktree — it always operates on the repository as a whole.
- `add` slugifies branch inputs segment-by-segment while preserving `/` as a
  nested branch/path delimiter, creates branches automatically, and fetches
  the remote default branch first. Missing arguments open fuzzy pickers on a
  real terminal only; in non-interactive use, always pass arguments or the
  command exits with an error.

## Core workflow

```sh
path=$(bonsai add <branch>)     # create or reuse; prints absolute path; idempotent
cd "$path"                      # then work inside the worktree
bonsai add <branch> --base HEAD # stack on the checkout you run it from
bonsai list --json              # this repo's worktrees, machine-readable
bonsai remove <branch> [-d]     # drop the worktree (keep branch unless -d)
bonsai clean --dry-run --json   # inspect merged/squash-merged/gone branches
bonsai clean --yes              # then execute
```

## Invariants you would otherwise get wrong

- `--base` resolves against the directory bonsai runs from, not the main
  checkout: `--base HEAD` inside a worktree stacks on that worktree.
- New branches carry no upstream (`--no-track`) until first push.
- A fresh worktree with zero commits already counts as "merged", so `clean`
  will list it — read the plan before executing.
- Untracked local config (`.env*`, `.envrc`, `.mcp.json`, `CLAUDE.local.md`,
  ...) is copied into new worktrees automatically.
- Dependencies are installed automatically in new worktrees when a lockfile
  is present (pnpm/npm/yarn/bun/cargo/uv, lockfile-frozen); a missing tool is
  skipped and an install failure never aborts `add` — check stderr before
  assuming deps are in place. Follow any linked package-manager configuration
  warning to enable its worktree-optimized shared store.

## Destructive-command policy

- Inspect first, then act: `bonsai clean --dry-run --json`, review, then
  `bonsai clean --yes`. Same for `prune` (`--yes` skips confirmation).
- Never pass `--force` or `-y`/`--yes` unattended unless the user explicitly
  asked for it. `clean` never touches dirty worktrees; `remove` refuses them
  without `--force`.

Flags drift; this file does not. Trust `bonsai <cmd> --help` for the exact
current interface.
