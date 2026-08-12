---
name: commit
description: Stage all changes and commit with an auto-generated message. Does NOT push.
---

## Task

1. **Gather context**: Run `git status --short`, `git diff --stat`, `git log --oneline -5`, and `git rev-parse --abbrev-ref HEAD`.

2. **Stage all changes**: Run `git add -A` to stage everything (tracked and untracked).

3. **Generate a commit message**: Analyze the staged diff (`git diff --cached`) and recent commit history. The message MUST follow the latest published [Conventional Commits specification](https://www.conventionalcommits.org/): `<type>[optional scope][optional !]: <description>`, followed by an optional body and optional footers separated by blank lines. Use `feat` for a feature and `fix` for a bug fix. Mark a breaking change with `!` before `:` or a `BREAKING CHANGE:` footer. Other types such as `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, and `test` are allowed when they accurately describe the change. Keep the first line under 72 characters. Add a body only if the change is non-trivial. If `$ARGUMENTS` is provided, use it as guidance — but still write and validate the message yourself.

4. **Commit**: Create the commit. Do NOT amend an existing commit. Do NOT use `--no-verify`. Do NOT push.

Report the commit message and number of files changed.
