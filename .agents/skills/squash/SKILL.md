---
name: squash
description: Squash all local commits (ahead of remote) into a single commit with an auto-generated message.
---

## Task

1. **Gather context**: Run `git rev-parse --abbrev-ref HEAD` and `git log --oneline @{upstream}..HEAD 2>/dev/null || git log --oneline $(git merge-base HEAD main)..HEAD` to see all local commits ahead of remote.

2. **Abort if nothing to squash**: If there are 0 or 1 local commits, tell the user there is nothing to squash and stop.

3. **Soft reset**: Run `git reset --soft @{upstream} 2>/dev/null || git reset --soft $(git merge-base HEAD main)` to unstage all local commits while keeping changes staged.

4. **Generate a commit message**: Analyze the staged diff (`git diff --cached`) and the list of squashed commit messages. Write a single concise conventional-commit-style message that summarizes all the squashed work. If `$ARGUMENTS` is provided, use it as guidance.

5. **Commit**: Create the commit. Do NOT use `--no-verify`. Do NOT push.

Report the new commit message and how many commits were squashed.
