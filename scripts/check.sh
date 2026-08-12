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

for command_name in actionlint git jq rg shellcheck shfmt stylua taplo tmux yq zsh; do
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
  if [ ! -e "$executable" ]; then
    git diff --quiet -- "$executable" || continue
  fi
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
rg -Fx 'bottom = "latest"' .config/mise/config.toml >/dev/null ||
  fail "Bottom must be installed through mise"
rg -Fx 'yq = "4.53.3"' .config/mise/config.toml >/dev/null ||
  fail "yq must be installed through mise"
rg -Fx 'alias htop=btm' .zshrc >/dev/null ||
  fail "htop must invoke the mise-managed Bottom CLI"
rg -F 'ChatGPT Pro/Plus (headless)' setup.sh >/dev/null ||
  fail "Linux OpenCode authentication must support headless machines"

toml_files=()
while IFS= read -r toml_file; do
  toml_files+=("$toml_file")
done < <(git ls-files '*.toml')
taplo check "${toml_files[@]}"
stylua --check .config/nvim
actionlint

yaml_files=()
while IFS= read -r yaml_file; do
  yaml_files+=("$yaml_file")
done < <(git ls-files '*.yaml' '*.yml')
if ((${#yaml_files[@]} > 0)); then
  yq eval '.' "${yaml_files[@]}" >/dev/null
fi

while IFS= read -r skill_file; do
  skill_name=$(basename "$(dirname "$skill_file")")
  SKILL_NAME="$skill_name" yq --front-matter=extract -e \
    '.name == strenv(SKILL_NAME) and (.description | type == "!!str" and . != "")' \
    "$skill_file" >/dev/null ||
    fail "$skill_file: frontmatter must define name=$skill_name and a non-empty description"
done < <(git ls-files '.agents/skills/*/SKILL.md')

section "Application configuration"
awk '
  /^[[:space:]]*($|#)/ { next }
  /^(tap|brew|cask) '\''[^'\'']+'\''([[:space:]]+#.*)?$/ { next }
  {
    printf "%s:%d: unsupported Brewfile line: %s\n", FILENAME, FNR, $0 > "/dev/stderr"
    bad = 1
  }
  END { exit bad }
' Brewfile
git config --file .gitconfig --list >/dev/null
RIPGREP_CONFIG_PATH="$repo_root/.config/ripgrep/rc" rg --files >/dev/null
bash setup.sh --help >/dev/null

if rg -q 'GITHUB_TOKEN|GH_TOKEN' .zprofile; then
  fail "shell startup must not shadow gh keyring authentication with token environment variables"
fi

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
rg -F '[Conventional Commits specification](https://www.conventionalcommits.org/)' AGENTS.md >/dev/null ||
  fail "AGENTS.md must require the latest Conventional Commits specification"
for commit_skill in .agents/skills/commit/SKILL.md .agents/skills/push/SKILL.md; do
  rg -F 'MUST follow the latest published [Conventional Commits specification](https://www.conventionalcommits.org/)' "$commit_skill" >/dev/null ||
    fail "$commit_skill must enforce the latest Conventional Commits specification"
done
rg -Fx 'export OPENCODE_DISABLE_CLAUDE_CODE=1' .zshenv >/dev/null ||
  fail "OpenCode must ignore Claude compatibility paths"
rg -Fx 'setopt SHARE_HISTORY' .zshrc >/dev/null ||
  fail "Zsh tabs must share history live"
rg -Fx 'unsetopt APPEND_HISTORY INC_APPEND_HISTORY' .zshrc >/dev/null ||
  fail "Zsh shared history must own incremental writes"
rg -Fx 'ipc_socket = true' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty same-process scratch startup requires IPC"
rg -F 'scratch-terminal.sh\" bootstrap' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty must launch the managed scratch window pair"
if rg -n '^bind [0-9]' .tmux.conf >/dev/null; then
  fail "numeric window selection must use tmux's built-in mappings"
fi
rg -Fx 'chars = "\u0011\u0031"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+1 must emit tmux prefix+1"
rg -Fx 'chars = "\u0011n"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+Shift+] must emit tmux prefix+n"
rg -Fx 'key = "}"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+Shift+] must match its shifted logical key"
rg -Fx 'key = "{"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+Shift+[ must match its shifted logical key"
rg -Fx 'chars = "\u0011v"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+D must emit tmux prefix+v"
rg -Fx 'chars = "\u0011d"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+R must ask tmux to detach cleanly"
rg -F 'scratch-terminal.sh\" reload' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+R must also restart an unreachable local transport"
rg -Fx 'set -g default-terminal "tmux-256color"' .tmux.conf >/dev/null ||
  fail "tmux panes must use the tmux-256color terminfo contract"
rg -Fx 'set-environment -g COLORTERM truecolor' .tmux.conf >/dev/null ||
  fail "tmux panes must advertise truecolor to every CLI application"
rg -Fx "set-environment -g COLORFGBG '15;0'" .tmux.conf >/dev/null ||
  fail "tmux panes must advertise the shared dark terminal palette"
rg -Fx 'foreground = "0xD8DEE9"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty must keep the shared Nord foreground"
rg -Fx 'background = "0x2E3440"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty must keep the shared Nord background"
rg -Fx 'black = "0x3B4252"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty must keep the shared Nord black"
rg -Fx 'set -g window-style fg=#D8DEE9,bg=#3B4252' .tmux.conf >/dev/null ||
  fail "inactive tmux panes must use the shared Nord foreground and black"
rg -Fx 'set -g window-active-style fg=#D8DEE9,bg=#2E3440' .tmux.conf >/dev/null ||
  fail "active tmux panes must expose Alacritty foreground and background colors"
if rg -n 'user-keys|bind -n User' .tmux.conf >/dev/null; then
  fail "Alacritty shortcuts must use normal tmux prefix mappings"
fi
rg -F 'scratch_tmp_root=$(cd "$scratch_tmp_root" && pwd -P)' scripts/scratch-terminal.sh >/dev/null ||
  fail "remote terminal reload state must use a physical macOS temporary path"
rg -F 'kill -TERM "$child_pid"' scripts/scratch-terminal.sh >/dev/null ||
  fail "remote terminal reload must request graceful transport shutdown"
rg -F 'kill -KILL "$child_pid"' scripts/scratch-terminal.sh >/dev/null ||
  fail "remote terminal reload must bound a stuck transport shutdown"
[ ! -e scripts/grid.sh ] || fail "retired tmux grid helper remains"
if rg -n 'grid\.sh|rows=3|cols=3' .tmux.conf >/dev/null; then
  fail "retired tmux grid mappings remain"
fi
rg -Fx "brew 'mosh'                    # Roaming transport for the Moria scratch window" Brewfile >/dev/null ||
  fail "Mosh must be provisioned on macOS"
[ ! -e .config/tmuxinator ] || fail "retired tmuxinator profiles remain"
if rg -n 'tmuxinator|headquarter|beside|session-picker' .tmux.conf scripts/status-click.sh >/dev/null; then
  fail "retired named-session routing remains configured"
fi

tmux_socket="dotfiles-check-$$"
cleanup_tmux() {
  tmux -L "$tmux_socket" kill-server >/dev/null 2>&1 || true
}
trap cleanup_tmux EXIT
tmux -L "$tmux_socket" -f /dev/null new-session -d -s check
for window_index in 1 2 9; do
  tmux -L "$tmux_socket" list-keys -T prefix "$window_index" |
    rg -F "select-window -t :=$window_index" >/dev/null ||
    fail "tmux default prefix+$window_index mapping is unavailable"
done
tmux -L "$tmux_socket" source-file -n .tmux.conf >/dev/null
cleanup_tmux
trap - EXIT

printf '\nAll checks passed.\n'
