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

require_relative_link() {
  local link="$1"
  local target="$2"

  [ -L "$link" ] || fail "missing compatibility symlink: $link"
  [ "$(readlink "$link")" = "$target" ] ||
    fail "wrong compatibility symlink: $link -> $(readlink "$link")"
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
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    git diff --quiet -- "$link" || continue
  fi
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
    scripts/lib.sh) continue ;;
  esac
  mode=$(git ls-files -s -- "$script" | awk '{ print $1 }')
  [ "$mode" = "100755" ] || fail "script is not executable: $script"
done < <(git grep -Il '^#!')

section "Shell syntax, lint, and formatting"
shell_files=(setup.sh .config/newsboat/run.sh scripts/*.sh)
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

jq -e '
  .model == "openai/gpt-5.6-sol" and
  .compaction == {"auto": true, "prune": true, "reserved": 20000} and
  (.mcp | keys) == ["semble"] and
  .mcp.semble == {
    "type": "local",
    "command": ["uvx", "--from", "semble[mcp]==0.5.4", "semble"],
    "enabled": true
  }
' .config/opencode/opencode.json >/dev/null

jq -e '
  .env.ENABLE_CLAUDEAI_MCP_SERVERS == "0" and
  .env.ENABLE_TOOL_SEARCH == "true" and
  [.permissions.allow[] | select(startswith("mcp__"))] == ["mcp__semble__*"] and
  ([.hooks.SessionStart[]?.hooks[]?.command] |
    any(contains("scripts/agent-instructions.sh")))
' .claude/settings.json >/dev/null

[ -f .config/opencode/plugins/rtk.ts ] || fail "missing OpenCode RTK plugin"
rg -Fx '"aqua:anomalyco/opencode" = "latest"' .config/mise/config.toml >/dev/null ||
  fail "OpenCode must be installed through mise"
rg -Fx '"pipx:semble" = "0.5.4"' .config/mise/config.toml >/dev/null ||
  fail "Semble CLI version must match the MCP configuration"
rg -F 'ChatGPT Pro/Plus (headless)' setup.sh >/dev/null ||
  fail "Linux OpenCode authentication must support headless machines"

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

frontmatter_files = Dir[".agents/skills/*/SKILL.md"].sort
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

if rg -n '^@' .agents/AGENTS.md >/dev/null; then
  fail ".agents/AGENTS.md must be self-contained; client-specific import syntax is not portable"
fi

claude_instruction_files=()
while IFS= read -r candidate; do
  case "$candidate" in
    CLAUDE.md | CLAUDE.local.md | */CLAUDE.md | */CLAUDE.local.md)
      if [ -e "$candidate" ] || [ -L "$candidate" ]; then
        claude_instruction_files+=("$candidate")
      fi
      ;;
  esac
done < <(git ls-files --cached --others --exclude-standard)
if ((${#claude_instruction_files[@]} > 0)); then
  printf '%s\n' "${claude_instruction_files[@]}" >&2
  fail "use standard AGENTS.md files instead of Claude-specific instruction files"
fi

for obsolete_path in .agents/agents .claude/CLAUDE.md .claude/agents .codex/agents .cursor; do
  [ ! -e "$obsolete_path" ] && [ ! -L "$obsolete_path" ] ||
    fail "obsolete client-specific compatibility path remains: $obsolete_path"
done
[ ! -L .codex/skills ] || fail "Codex must discover personal skills from .agents/skills natively"

require_relative_link .codex/AGENTS.md ../.agents/AGENTS.md
require_relative_link .config/opencode/AGENTS.md ../../.agents/AGENTS.md
require_relative_link .claude/skills ../.agents/skills
rg -Fx 'export OPENCODE_DISABLE_CLAUDE_CODE=1' .zshenv >/dev/null ||
  fail "OpenCode must ignore Claude compatibility paths"
rg -Fx 'setopt SHARE_HISTORY' .zshrc >/dev/null ||
  fail "Zsh tabs must share history live"
rg -Fx 'unsetopt APPEND_HISTORY INC_APPEND_HISTORY' .zshrc >/dev/null ||
  fail "Zsh shared history must own incremental writes"

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
