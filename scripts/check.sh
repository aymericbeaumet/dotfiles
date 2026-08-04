#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

repo_root=$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

section() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || fail "required validator not found: $1"
}

for command_name in actionlint git jq rg ruby shellcheck shfmt stylua taplo tmux zsh; do
  require "$command_name"
done

section "Repository hygiene"
git diff --check

if trailing_whitespace=$(git grep -nI -E '[[:blank:]]+$' -- .); then
  printf '%s\n' "$trailing_whitespace" >&2
  fail "tracked files contain trailing whitespace"
fi

if conflict_markers=$(git grep -nI -E '^(<<<<<<< |=======|>>>>>>> )' -- .); then
  printf '%s\n' "$conflict_markers" >&2
  fail "tracked files contain merge-conflict markers"
fi

case_collisions=$(git ls-files | awk '{ print tolower($0) }' | sort | uniq -d)
[ -z "$case_collisions" ] || fail "case-insensitive path collisions:\n$case_collisions"

large_files=$(git ls-tree -r -l HEAD | awk '$4 ~ /^[0-9]+$/ && $4 > 5242880 { print $4, $5 }')
[ -z "$large_files" ] || fail "tracked files exceed 5 MiB:\n$large_files"

while IFS= read -r link; do
  [ -L "$link" ] || fail "tracked symlink was checked out as a regular file: $link"
  [ -e "$link" ] || fail "broken tracked symlink: $link -> $(readlink "$link")"
  case "$(readlink "$link")" in
    /*) fail "tracked symlink must use a relative target: $link" ;;
  esac
done < <(git ls-files -s | awk '$1 == "120000" { print $4 }')

while IFS= read -r executable; do
  [ "$(head -c 2 "$executable")" = '#!' ] || fail "tracked executable lacks a shebang: $executable"
done < <(git ls-files -s | awk '$1 == "100755" { print $4 }')

while IFS= read -r script; do
  case "$script" in
    .claude/statusline-command.sh | scripts/lib.sh) continue ;;
  esac
  mode=$(git ls-files -s -- "$script" | awk '{ print $1 }')
  [ "$mode" = "100755" ] || fail "script is not executable: $script"
done < <(git grep -Il '^#!')

section "Shell syntax, lint, and formatting"
shell_files=(setup.sh .claude/statusline-command.sh .config/newsboat/run.sh scripts/*.sh)
for shell_file in "${shell_files[@]}"; do
  case "$(head -n 1 "$shell_file")" in
    *bash*) bash -n "$shell_file" ;;
    *) sh -n "$shell_file" ;;
  esac
done

zsh -n .p10k.zsh .zprofile .zshenv .zshrc
shellcheck --severity=warning "${shell_files[@]}"
shfmt -d -i 2 -ci "${shell_files[@]}"

section "Structured configuration"
while IFS= read -r json_file; do
  jq empty "$json_file"
done < <(git ls-files '*.json')

toml_files=()
while IFS= read -r toml_file; do
  toml_files+=("$toml_file")
done < <(git ls-files '*.toml')
taplo check "${toml_files[@]}"
stylua --check .config/nvim
actionlint

ruby <<'RUBY'
require "yaml"

Encoding.default_external = Encoding::UTF_8

yaml_files = IO.popen(["git", "ls-files", "*.yaml", "*.yml"], &:read).split("\n")
yaml_files.each { |path| YAML.load_file(path) }

frontmatter_files = Dir[".agents/agents/*.md", ".agents/skills/*/SKILL.md"].sort
frontmatter_files.each do |path|
  content = File.read(path)
  parts = content.split(/^---\s*$\n?/, 3)
  abort "#{path}: missing YAML frontmatter" unless parts.length == 3 && parts.first.empty?

  metadata = YAML.load(parts[1])
  abort "#{path}: frontmatter must be a mapping" unless metadata.is_a?(Hash)
  %w[name description].each do |key|
    abort "#{path}: missing #{key}" unless metadata[key].is_a?(String) && !metadata[key].empty?
  end

  next unless path.end_with?("/SKILL.md")

  directory_name = File.basename(File.dirname(path))
  abort "#{path}: skill name must match directory" unless metadata["name"] == directory_name
end
RUBY

section "Application configuration"
ruby -c Brewfile >/dev/null
git config --file .gitconfig --list >/dev/null
RIPGREP_CONFIG_PATH="$repo_root/.config/ripgrep/rc" rg --files >/dev/null
bash setup.sh --help >/dev/null

while IFS= read -r import; do
  imported_file=".agents/${import#@./}"
  [ -f "$imported_file" ] || fail "missing AGENTS import: $imported_file"
done < <(awk '/^@\.\// { print }' .agents/AGENTS.md)

tmux_socket="dotfiles-check-$$"
cleanup_tmux() {
  tmux -L "$tmux_socket" kill-server >/dev/null 2>&1 || true
}
trap cleanup_tmux EXIT
tmux -L "$tmux_socket" -f /dev/null new-session -d -s check
tmux -L "$tmux_socket" source-file -n .tmux.conf >/dev/null
cleanup_tmux
trap - EXIT

printf '\nAll checks passed.\n'
