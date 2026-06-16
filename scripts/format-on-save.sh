#!/usr/bin/env bash
# PostToolUse hook: format edited files in-place per language.
# Reads tool input JSON on stdin, extracts file_path, formats it.
# Always exits 0 — never blocks the agent on formatter failure.

set -u

input=$(cat 2>/dev/null || true)
[ -z "$input" ] && exit 0

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

case "$file" in
  *.rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt --edition 2021 "$file" 2>/dev/null
    ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$file" 2>/dev/null
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.jsonc|*.md|*.mdx|*.css|*.scss|*.html|*.yaml|*.yml|*.svelte|*.vue)
    command -v prettier >/dev/null 2>&1 && prettier --write --log-level error "$file" 2>/dev/null
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format --quiet "$file" 2>/dev/null
    elif command -v black >/dev/null 2>&1; then
      black --quiet "$file" 2>/dev/null
    fi
    ;;
  *.sh|*.bash|*.zsh)
    command -v shfmt >/dev/null 2>&1 && shfmt -w -i 2 -ci "$file" 2>/dev/null
    ;;
  *.toml)
    command -v taplo >/dev/null 2>&1 && taplo format --option column_width=120 "$file" 2>/dev/null
    ;;
  *.lua)
    command -v stylua >/dev/null 2>&1 && stylua "$file" 2>/dev/null
    ;;
  *.nix)
    command -v nixpkgs-fmt >/dev/null 2>&1 && nixpkgs-fmt "$file" 2>/dev/null
    ;;
  *.sql)
    command -v sqlfluff >/dev/null 2>&1 && sqlfluff format --quiet "$file" 2>/dev/null
    ;;
esac

exit 0
