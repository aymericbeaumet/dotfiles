---
name: squash
description: Squash local commits ahead of the configured base into one Conventional Commit. Use when the user asks to squash committed branch work.
---

# Squash

Do not stage or include pending worktree changes. Require a clean worktree and index; when either is
dirty, stop and ask the user to commit or discard that work first.

1. Inspect the current branch, worktree and index status, configured upstream, recent commits, and
   remotes.
2. Use the configured upstream as the base. If none exists, resolve the remote default branch and
   use its merge base with `HEAD`; ask when no base is unambiguous.
3. List commits between the base and `HEAD`. If there are zero or one, report that there is nothing
   to squash and stop.
4. Run `git reset --soft <base>` so the committed branch changes remain staged.
5. Analyze the complete staged diff and all squashed commit messages. The final message MUST follow the latest published [Conventional Commits specification](https://www.conventionalcommits.org/), keep
   its first line under 72 characters, and incorporate any user-provided message guidance.
6. Create the replacement commit without bypassing hooks. Do not push.

Report the final commit message, base, and number of commits squashed.
