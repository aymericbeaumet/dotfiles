---
name: pr
description: Create a new pull request or update an existing one's title and description. Use when the user asks to open a PR, submit a PR, update a PR, or push changes for review.
---

## Task

1. **Gather context**: Run these commands to understand the current state:
   - `git rev-parse --abbrev-ref HEAD` to get the current branch
   - `git log --oneline -10` to see recent commits
   - `gh pr view --json number,title,body,url 2>&1` to check for an existing PR

2. **Detect PR template**: Look for a pull request template in the repo. Check these paths in order and use the first one found:
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `docs/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE/*.md` (if multiple, pick `default.md` or the first one)

3. **Determine base branch**: Use `main` or `master` (whichever exists on the remote). If neither, ask the user.

4. **Analyze changes**: Run `git log --oneline $(git merge-base HEAD <base>)..HEAD` and `git diff <base>...HEAD --stat` to understand all commits on this branch.

5. **Check for existing PR**: If `gh pr view` succeeded in step 1, a PR already exists — go to step 7 (update). Otherwise, go to step 6 (create).

6. **Create PR**:
   - Push the branch if it hasn't been pushed yet: `git push -u origin HEAD`.
   - Draft a title (under 72 characters) and a description body.
   - If a PR template was found in step 2, use it as the structure for the body. Fill in every section of the template based on the actual changes. Do not skip or remove sections — leave them with a "N/A" note if truly not applicable.
   - If no template was found, use this format:
     ```
     ## Summary
     <bullet points describing the changes>

     ## Test plan
     <how to verify the changes>
     ```
   - If the user provided arguments, use them as guidance for the title and description.
   - Create the PR with `gh pr create --title "..." --body "$(cat <<'EOF' ... EOF)"`.

7. **Update existing PR**:
   - Push any local commits: `git push`.
   - Re-analyze the full diff against base to capture any new commits.
   - Draft an updated title and description that reflects the current state of all changes on the branch.
   - If a PR template was found in step 2, use it as the structure for the updated body. Fill in every section.
   - If the user provided arguments, use them as guidance for the updated title and description.
   - Update with `gh pr edit --title "..." --body "$(cat <<'EOF' ... EOF)"`.

Report the PR URL at the end.
