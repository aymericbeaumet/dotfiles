---
name: push
description: Synchronize and push existing commits without staging or committing. Use when the user asks to push or publish the current branch.
---

# Push

Do not stage files or create, amend, squash, or otherwise rewrite commits except for the explicit
upstream rebase below. Preserve all staged and unstaged worktree changes.

1. Inspect the current branch, worktree and index status, configured upstream, recent commits, and
   remotes.
2. Fetch the current branch's remote when it has an upstream.
3. Compare `HEAD` with its upstream. When the upstream is ahead or histories diverged, require a
   clean worktree and index, then rebase onto the upstream.
4. If rebase conflicts occur, resolve clear conflicts, stage only the resolutions, and continue the
   rebase. If a resolution is ambiguous or risky, abort the rebase and stop the pipeline.
5. Push with `git push`. If no upstream exists, use `git push -u origin HEAD` after confirming that
   `origin` exists.
6. Never force-push or bypass hooks.

Report the branch, synchronization performed, and push result.
