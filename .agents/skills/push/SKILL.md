---
name: push
description: Stage all changes, commit with an auto-generated message, pull/rebase remote, and push.
---

## Task

1. **Gather context**: Run `git status --short`, `git diff --stat`, `git log --oneline -5`, and `git rev-parse --abbrev-ref HEAD`.

2. **Stage all changes**: Run `git add -A` to stage everything (tracked and untracked).

3. **Generate a commit message**: Analyze the staged diff (`git diff --cached`) and recent commit history. Write a concise, conventional-commit-style message (e.g. `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`). The first line must be under 72 characters. Add a body only if the change is non-trivial. If `$ARGUMENTS` is provided, use it as guidance for the commit message — but still write the message yourself.

4. **Commit**: Create the commit. Do NOT amend an existing commit. Do NOT use `--no-verify`.

5. **Pull with rebase**: Run `git pull --rebase` to fetch and rebase on top of the remote branch. If the current branch has no upstream, skip this step.
   - If there are rebase conflicts, attempt to resolve them automatically by reading the conflicted files, making sensible choices, staging the resolved files, and running `git rebase --continue`. If a conflict is ambiguous or risky, abort the rebase (`git rebase --abort`) and report the issue to the user — do NOT force through.

6. **Push**: Run `git push`. If the branch has no upstream, use `git push -u origin HEAD`.

Report the commit message, number of files changed, and whether the push succeeded.
