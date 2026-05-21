---
name: commit
description: Stage all changes and commit with an auto-generated message. Does NOT push.
---

## Task

1. **Gather context**: Run `git status --short`, `git diff --stat`, `git log --oneline -5`, and `git rev-parse --abbrev-ref HEAD`.

2. **Stage all changes**: Run `git add -A` to stage everything (tracked and untracked).

3. **Generate a commit message**: Analyze the staged diff (`git diff --cached`) and recent commit history. Write a concise, conventional-commit-style message (e.g. `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`). The first line must be under 72 characters. Add a body only if the change is non-trivial. If `$ARGUMENTS` is provided, use it as guidance for the commit message — but still write the message yourself.

4. **Commit**: Create the commit. Do NOT amend an existing commit. Do NOT use `--no-verify`. Do NOT push.

Report the commit message and number of files changed.
