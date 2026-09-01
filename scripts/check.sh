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

for command_name in actionlint git jq node rg shellcheck shfmt stylua taplo tmux yq zsh; do
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
  .small_model == "openai/gpt-5.6-luna-fast" and
  .compaction == {"auto": true, "prune": true, "reserved": 20000, "tail_turns": 15} and
  .permission == "allow" and
  .tool_output == {"max_lines": 200, "max_bytes": 8192} and
  .agent.explore == {"model": "openai/gpt-5.6-luna-fast", "variant": "low"} and
  .provider.openai.models."gpt-5.6-sol".variants.none.disabled == true and
  (.mcp | keys) == ["semble"] and
  .mcp.semble == {
    "type": "local",
    "command": ["uvx", "--from", "semble[mcp]==0.5.4", "semble"],
    "enabled": true,
    "timeout": 30000
  } and
  .instructions == ["attribution.md"]
' .config/opencode/opencode.json >/dev/null

jq -e '
  .env.CLAUDE_CODE_RETRY_WATCHDOG == "1" and
  .env.CLAUDE_CODE_DISABLE_AUTO_MEMORY == "1" and
  .env.ENABLE_CLAUDEAI_MCP_SERVERS == "0" and
  .env.ENABLE_TOOL_SEARCH == "true" and
  .autoMemoryEnabled == false and
  .tui == "fullscreen" and
  .attribution == {"commit": "", "pr": "", "sessionUrl": false} and
  [.permissions.allow[] | select(startswith("mcp__"))] == ["mcp__semble__*"] and
  (.permissions.deny | index("EnterWorktree")) != null and
  (.permissions.deny | index("ExitWorktree")) != null and
  ([.hooks.PreToolUse[]?.hooks[]?.command] |
    any(contains("scripts/worktree-guard.sh"))) and
  ([.hooks.SessionStart[]?.hooks[]?.command] |
    any(contains("scripts/agent-instructions.sh"))) and
  ([.hooks.SessionStart[]?.hooks[]?.command] |
    any(contains("scripts/project-memory.sh"))) and
  ([.hooks.StopFailure[]?.hooks[]?.command] |
    any(contains("scripts/claude-retry.sh failure"))) and
  ([.hooks.Stop[]?.hooks[]?.command] |
    any(contains("scripts/claude-retry.sh reset")))
' .claude/settings.json >/dev/null
rg -Fx '.claude/settings.json filter=claude-settings' .gitattributes >/dev/null ||
  fail "Claude settings must use a git filter so model and effort stay local"
git config --file .gitconfig --get filter.claude-settings.clean |
  rg -F 'scripts/claude-settings-clean.jq' >/dev/null ||
  fail "gitconfig must clean Claude settings with scripts/claude-settings-clean.jq"
printf '%s\n' '{"model":"x","effortLevel":"high","tui":"fullscreen","theme":"auto"}' |
  jq --indent 2 -f scripts/claude-settings-clean.jq |
  jq -e '(has("model") | not) and (has("effortLevel") | not) and .tui == "fullscreen" and .theme == "auto"' >/dev/null ||
  fail "Claude settings clean filter must drop model and effortLevel"

jq -e '
  .theme == "nord" and
  .mouse == true and
  .scroll_acceleration.enabled == true and
  .keybinds.app_exit == "ctrl+d,<leader>q" and
  .keybinds.session_interrupt == "escape,ctrl+c" and
  .keybinds.input_clear == "none" and
  .keybinds.command_list == "<leader>p" and
  .keybinds.input_move_left == "left,ctrl+b" and
  .keybinds.input_move_right == "right,ctrl+f" and
  .keybinds.input_move_up == "up,ctrl+p" and
  .keybinds.input_move_down == "down,ctrl+n" and
  .keybinds.history_previous == "up,ctrl+p" and
  .keybinds.history_next == "down,ctrl+n" and
  .keybinds.model_cycle_favorite == "f3" and
  .keybinds.model_cycle_favorite_reverse == "shift+f3" and
  .keybinds.variant_cycle == "ctrl+t" and
  .keybinds.variant_list == "<leader>v"
' .config/opencode/tui.json >/dev/null

jq -e '
  .defaultProvider == "openai-codex" and
  .defaultModel == "gpt-5.6-sol" and
  .defaultThinkingLevel == "xhigh" and
  .enabledModels == [
    "openai-codex/gpt-5.6-sol",
    "openai-codex/gpt-5.6-terra",
    "openai-codex/gpt-5.6-luna"
  ] and
  .theme == "nord" and
  .tuiMode == "fullscreen" and
  .fullscreenExitOutput == "resume-hint" and
  .fullscreenScrollbar == "auto" and
  .defaultProjectTrust == "ask" and
  .enableInstallTelemetry == false and
  .compaction == {"enabled": true, "reserveTokens": 20000, "keepRecentTokens": 20000} and
  .extensions[0] == "extensions/project-memory.ts" and
  (.extensions | index("extensions/tmux-title.ts")) != null
' .pi/agent/settings.json >/dev/null
jq -e '
  .name == "nord" and
  .vars.nord0 == "#2e3440" and
  .colors.accent == "nord8" and
  .export.pageBg == "nord0"
' .pi/agent/themes/nord.json >/dev/null
jq -e '
  ."tui.editor.cursorLeft" == ["left", "ctrl+b"] and
  ."tui.editor.cursorRight" == ["right", "ctrl+f"] and
  ."tui.editor.historyPrevious" == "ctrl+p" and
  ."tui.editor.historyNext" == "ctrl+n" and
  ."app.model.cycleForward" == "f3" and
  ."app.model.cycleBackward" == "shift+f3" and
  ."app.thinking.cycle" == "ctrl+t" and
  ."app.thinking.toggle" == "ctrl+shift+t"
' .pi/agent/keybindings.json >/dev/null
jq -e '
  (.providers."openai-codex".modelOverrides."gpt-5.6-sol".thinkingLevelMap | has("minimal")) and
  .providers."openai-codex".modelOverrides."gpt-5.6-sol".thinkingLevelMap.minimal == null and
  (.providers."openai-codex".modelOverrides."gpt-5.6-terra".thinkingLevelMap | has("minimal")) and
  .providers."openai-codex".modelOverrides."gpt-5.6-terra".thinkingLevelMap.minimal == null and
  (.providers."openai-codex".modelOverrides."gpt-5.6-luna".thinkingLevelMap | has("minimal")) and
  .providers."openai-codex".modelOverrides."gpt-5.6-luna".thinkingLevelMap.minimal == null
' .pi/agent/models.json >/dev/null
jq -e '
  any(.bindings[]; .context == "Chat" and .bindings."ctrl+t" == "chat:modelPicker") and
  any(.bindings[]; .context == "ModelPicker" and .bindings."ctrl+t" == "modelPicker:increaseEffort")
' .claude/keybindings.json >/dev/null

jq -e '
  (.hooks | keys) == ["PostToolUse", "PreToolUse", "SessionStart", "Stop", "UserPromptSubmit"] and
  any(.hooks.PreToolUse[]?.hooks[]?; .command | contains("scripts/worktree-guard.sh")) and
  ([.hooks.SessionStart[]?.hooks[]? |
    select(.command | contains("scripts/project-memory.sh"))] | length) == 1 and
  ([.hooks.SessionStart[]?.hooks[]? |
    select(.command | contains("scripts/project-memory.sh"))][0].additionalContextLimit) == 0 and
  any(.hooks.SessionStart[]?.hooks[]?; .command | contains("scripts/agent-pane-idle.sh clear")) and
  any(.hooks.UserPromptSubmit[]?.hooks[]?; .command | contains("scripts/agent-pane-idle.sh busy")) and
  any(.hooks.Stop[]?.hooks[]?; .command | contains("scripts/agent-pane-idle.sh idle")) and
  any(.hooks.Stop[]?.hooks[]?; .command | contains("scripts/agent-pane-title.sh codex")) and
  any(.hooks.PostToolUse[]?; .matcher == "Edit|Write|apply_patch") and
  any(.hooks.PostToolUse[]?.hooks[]?; .command | contains("scripts/format-on-save.sh"))
' .codex/hooks.json >/dev/null

[ -f .config/opencode/plugins/rtk.ts ] || fail "missing OpenCode RTK plugin"
[ -f .config/opencode/plugins/transient-retry.ts ] || fail "missing OpenCode transient-retry plugin"
[ -f .config/opencode/plugins/project-memory.ts ] || fail "missing OpenCode project-memory plugin"
[ -f .config/opencode/plugins/tmux-pane.ts ] || fail "missing OpenCode tmux-pane plugin"
[ -f .config/opencode/plugins/worktree-guard.ts ] || fail "missing OpenCode worktree-guard plugin"
[ -f .pi/agent/extensions/project-memory.ts ] || fail "missing Pi project-memory extension"
[ -x scripts/claude-retry.sh ] || fail "Claude retry hook must be executable"
[ -x scripts/worktree-guard.sh ] || fail "worktree guard must be executable"
[ -x scripts/project-memory.sh ] || fail "project-memory helper must be executable"
[ -x scripts/configure-codex-hooks.mjs ] || fail "Codex hook configurator must be executable"
node --check scripts/configure-codex-hooks.mjs

check_project_memory() (
  local test_root repo expected actual local_repo local_path commit_repo commit_path conflict_repo
  test_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-project-memory.XXXXXX")
  test_root=$(CDPATH='' cd "$test_root" && pwd -P)
  trap 'rm -rf "$test_root"' EXIT

  repo="$test_root/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" remote add origin git@github.com:aymericbeaumet/dotfiles.git
  expected="$test_root/store/git-aa1ddcd98e9d98e5f6cc1d399d077896b1f2f01b9af943741b73af6cd8a33b6e/MEMORY.md"
  actual=$(PROJECT_MEMORY_ROOT="$test_root/store" scripts/project-memory.sh --path "$repo")
  [ "$actual" = "$expected" ] || fail "project-memory SSH identity is unstable: $actual"
  [ -L "$repo/.memories" ] || fail "project-memory helper did not create the project symlink"
  [ "$(readlink "$repo/.memories")" = "${expected%/MEMORY.md}" ] ||
    fail "project-memory helper did not create an absolute canonical symlink"

  git -C "$repo" remote set-url origin https://github.com/aymericbeaumet/dotfiles.git
  actual=$(PROJECT_MEMORY_ROOT="$test_root/store" scripts/project-memory.sh --path "$repo")
  [ "$actual" = "$expected" ] || fail "equivalent HTTPS and SSH remotes use different memory"
  PROJECT_MEMORY_ROOT="$test_root/store" scripts/project-memory.sh "$repo" |
    rg -F '# Project Memory' >/dev/null || fail "project-memory helper did not render memory"

  local_repo="$test_root/home/local"
  mkdir -p "$local_repo"
  git -C "$local_repo" init -q
  git -C "$local_repo" remote add origin "file://$test_root/local-remote"
  local_path=$(HOME="$test_root/home" PROJECT_MEMORY_ROOT="$test_root/store" \
    scripts/project-memory.sh --path "$local_repo")
  case "$local_path" in
    "$test_root/store/path-"*/MEMORY.md) ;;
    *) fail "unborn local repository did not use path identity: $local_path" ;;
  esac

  commit_repo="$test_root/commit"
  mkdir -p "$commit_repo"
  git -C "$commit_repo" init -q
  git -C "$commit_repo" -c user.name=check -c user.email=check@example.com \
    commit --allow-empty -qm root
  commit_path=$(PROJECT_MEMORY_ROOT="$test_root/store" \
    scripts/project-memory.sh --path "$commit_repo")
  case "$commit_path" in
    "$test_root/store/commit-"*/MEMORY.md) ;;
    *) fail "repository without a remote did not use root-commit identity: $commit_path" ;;
  esac

  conflict_repo="$test_root/conflict"
  mkdir -p "$conflict_repo/.memories"
  git -C "$conflict_repo" init -q
  git -C "$conflict_repo" remote add origin git@github.com:example/conflict.git
  if PROJECT_MEMORY_ROOT="$test_root/store" \
    scripts/project-memory.sh --path "$conflict_repo" >/dev/null 2>&1; then
    fail "project-memory helper replaced a conflicting project path"
  fi
  [ -d "$conflict_repo/.memories" ] || fail "project-memory helper removed a conflicting path"
)
check_project_memory

check_agent_quota_status() (
  local test_root now first_day_now reset_iso reset_epoch earlier_reset later_reset
  local subday_reset almost_day_reset
  local claude_tsv codex_tsv grok_json grok_tsv output
  test_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-agent-quota.XXXXXX")
  trap 'rm -rf "$test_root"' EXIT
  now=1892937600
  first_day_now=1892851200
  reset_iso=2030-01-01T00:00:00.000000+00:00
  reset_epoch=1893456000

  claude_tsv=$(printf '30\t%s\t10\t%s' "$reset_iso" "$reset_iso")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CLAUDE_TSV="$claude_tsv" scripts/agent-quota-status.sh --claude)
  [ "$output" = '#[fg=#D08770]70%↻6d#[fg=colour245]' ] ||
    fail "Claude weekly quota must warn when usage is ahead of elapsed weekly pace: $output"

  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CLAUDE_TSV="$claude_tsv" scripts/agent-quota-status.sh --fable)
  [ "$output" = '90%↻6d' ] || fail "Fable scoped weekly quota was not rendered: $output"

  codex_tsv=$(printf '30\t%s\t10080' "$reset_epoch")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CODEX_TSV="$codex_tsv" scripts/agent-quota-status.sh --codex)
  [ "$output" = '#[fg=#D08770]70%↻6d#[fg=colour245]' ] ||
    fail "Codex weekly quota must warn when usage is ahead of elapsed weekly pace: $output"

  grok_tsv=$(printf '35\t%s\t10080' "$reset_iso")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_GROK_TSV="$grok_tsv" scripts/agent-quota-status.sh --grok)
  [ "$output" = '#[fg=#D08770]65%↻6d#[fg=colour245]' ] ||
    fail "Grok weekly quota was not rendered: $output"

  grok_json=$(printf '{"config":{"currentPeriod":{"type":"USAGE_PERIOD_TYPE_WEEKLY","end":"%s"}}}' \
    "$reset_iso")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_GROK_JSON="$grok_json" scripts/agent-quota-status.sh --grok)
  [ "$output" = '100%↻6d' ] ||
    fail "Grok must treat an omitted productUsage field as an unused weekly quota: $output"

  claude_tsv=$(printf '14\t%s\tnull\tnull' "$reset_iso")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$first_day_now" \
    AGENT_QUOTA_TEST_CLAUDE_TSV="$claude_tsv" scripts/agent-quota-status.sh --claude)
  [ "$output" = '86%↻7d' ] ||
    fail "the current quota day must include its full 100/7 allowance: $output"

  claude_tsv=$(printf '15\t%s\tnull\tnull' "$reset_iso")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$first_day_now" \
    AGENT_QUOTA_TEST_CLAUDE_TSV="$claude_tsv" scripts/agent-quota-status.sh --claude)
  [ "$output" = '#[fg=#D08770]85%↻7d#[fg=colour245]' ] ||
    fail "weekly quota must warn after exceeding the current day's allowance: $output"

  earlier_reset=$((now + 5 * 86400 + 23 * 3600))
  later_reset=$((now + 6 * 86400 + 1 * 3600))
  codex_tsv=$(printf '0\t%s\t10080' "$earlier_reset")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CODEX_TSV="$codex_tsv" scripts/agent-quota-status.sh --codex)
  [ "$output" = '100%↻5d' ] || fail "5d23h must floor to 5d: $output"
  codex_tsv=$(printf '0\t%s\t10080' "$later_reset")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CODEX_TSV="$codex_tsv" scripts/agent-quota-status.sh --codex)
  [ "$output" = '100%↻6d' ] || fail "6d01h must floor to 6d: $output"
  subday_reset=$((now + 5 * 3600))
  codex_tsv=$(printf '0\t%s\t10080' "$subday_reset")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CODEX_TSV="$codex_tsv" scripts/agent-quota-status.sh --codex)
  [ "$output" = '100%↻5h' ] || fail "remaining under 1d must render hours: $output"
  almost_day_reset=$((now + 23 * 3600))
  codex_tsv=$(printf '0\t%s\t10080' "$almost_day_reset")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CODEX_TSV="$codex_tsv" scripts/agent-quota-status.sh --codex)
  [ "$output" = '100%↻23h' ] || fail "23h remaining must render hours: $output"

  claude_tsv=$(printf '81\t%s\tnull\tnull' "$reset_iso")
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    AGENT_QUOTA_TEST_CLAUDE_TSV="$claude_tsv" scripts/agent-quota-status.sh --claude)
  [ "$output" = '#[fg=colour196]19%↻6d#[fg=colour245]' ] ||
    fail "critical weekly quota must remain red instead of orange: $output"

  mkdir -p "$test_root/tmux-agent-quota-status"
  printf '50\t%s\t30\t%s\t10\t%s' "$reset_iso" "$reset_iso" "$reset_iso" \
    >"$test_root/tmux-agent-quota-status/claude-usage-v2.tsv"
  printf '%s' "$((now + 3600))" >"$test_root/tmux-agent-quota-status/claude-usage-v3.next"
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    scripts/agent-quota-status.sh --claude)
  [ "$output" = '#[fg=#D08770]70%↻6d#[fg=colour245]' ] ||
    fail "Claude must keep last-good weekly usage when the live fetch is in backoff: $output"
  case "$output" in
    *h*) fail "Claude status must not render a session or daily window: $output" ;;
  esac
  output=$(TMPDIR="$test_root" AGENT_QUOTA_REFRESH=1 AGENT_QUOTA_TEST_NOW="$now" \
    scripts/agent-quota-status.sh --fable)
  [ "$output" = '90%↻6d' ] ||
    fail "Fable must keep last-good weekly usage when the live fetch is in backoff: $output"
)
check_agent_quota_status

rg -F '.kind == "weekly_scoped"' scripts/agent-quota-status.sh >/dev/null ||
  fail "Claude quota parsing must include model-scoped Fable usage"
if rg -n 'five_hour|\?%↻\?h' scripts/agent-quota-status.sh >/dev/null; then
  fail "status bar must not render session or daily quotas"
fi
rg -F 'agent-quota-status.sh --fable' .config/flash/flash.toml >/dev/null ||
  fail "Flash status bar must render the Fable quota"
rg -F 'agent-quota-status.sh --grok' .config/flash/flash.toml >/dev/null ||
  fail "Flash status bar must render the Grok quota"

printf '%s\n' \
  '{"error":"unknown","error_details":"API Error: Connection closed mid-response"}' |
  scripts/claude-retry.sh classify || fail "Claude retry hook missed a transient connection error"
if printf '%s\n' \
  '{"error":"unknown","error_details":"Authentication failed"}' |
  scripts/claude-retry.sh classify; then
  fail "Claude retry hook must not retry permanent authentication errors"
fi
rg -Fx '"aqua:anomalyco/opencode" = "latest"' .config/mise/config.toml >/dev/null ||
  fail "OpenCode must be installed through mise"
rg -Fx '"npm:@earendil-works/pi-coding-agent" = "latest"' .config/mise/config.toml >/dev/null ||
  fail "Pi must be installed through mise"
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
rg -F "run 'pi', then '/login openai-codex'" setup.sh >/dev/null ||
  fail "setup must explain Pi's separate ChatGPT authentication"
rg -F '"$CLAUDE_MISE_ROOT/node_modules/@anthropic-ai/claude-code/install.cjs"' setup.sh >/dev/null ||
  fail "Claude postinstall repair must support mise's aube npm layout"
rg -F '"$CLAUDE_MISE_ROOT/lib/node_modules/@anthropic-ai/claude-code/install.cjs"' setup.sh >/dev/null ||
  fail "Claude postinstall repair must support mise's legacy npm layout"

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
  [ -e "$skill_file" ] || continue
  skill_name=$(basename "$(dirname "$skill_file")")
  SKILL_NAME="$skill_name" yq --front-matter=extract -e \
    '.name == strenv(SKILL_NAME) and (.description | type == "!!str" and . != "")' \
    "$skill_file" >/dev/null ||
    fail "$skill_file: frontmatter must define name=$skill_name and a non-empty description"
done < <(git ls-files --cached --others --exclude-standard '.agents/skills/*/SKILL.md')

section "Application configuration"
awk '
  /^[[:space:]]*($|#)/ { next }
  /^tap '\''[^'\'']+'\'', trusted: true([[:space:]]+#.*)?$/ { next }
  /^(brew|cask) '\''[^'\'']+'\''([[:space:]]+#.*)?$/ { next }
  {
    printf "%s:%d: unsupported Brewfile line: %s\n", FILENAME, FNR, $0 > "/dev/stderr"
    bad = 1
  }
  END { exit bad }
' Brewfile
rg -F 'brew bundle cleanup --force --no-tap --file ./Brewfile' setup.sh >/dev/null ||
  fail "Homebrew Bundle cleanup must leave tap removal to the noninteractive force-untap pass"
rg -F 'HOMEBREW_NO_REQUIRE_TAP_TRUST=1 brew untap --force "$tap_name"' setup.sh >/dev/null ||
  fail "stale Homebrew taps must be removed without prompting"
rg -Fx "brew 'mole'" Brewfile >/dev/null ||
  fail "Mole must use its current Homebrew Core formula"
if rg -n 'tw93/tap' Brewfile >/dev/null; then
  fail "retired Mole tap remains in Brewfile"
fi
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
[ ! -e .agents/skills/.system ] || fail "client-managed system skills must not leak into the shared skill tree"
for atomic_skill in commit push squash; do
  [ -f ".agents/skills/$atomic_skill/SKILL.md" ] || fail "missing atomic $atomic_skill skill"
done
[ -f .agents/skills/pullrequest/SKILL.md ] || fail "missing one-shot pullrequest skill"
for obsolete_skill in commitpush commitsquash pr prcheck prready; do
  [ ! -e ".agents/skills/$obsolete_skill/SKILL.md" ] ||
    fail "obsolete Git workflow $obsolete_skill skill remains"
done
[ ! -e .handouts/.gitkeep ] || fail "project handouts must not contain a tracked placeholder"
[ -f .config/opencode/commands/handout.md ] || fail "missing OpenCode handout command"
[ -f .config/opencode/commands/distill.md ] || fail "missing OpenCode distill command"
[ -f .config/opencode/commands/enrich-blueprint.md ] || fail "missing OpenCode enrich-blueprint command"
[ -f .pi/agent/prompts/handout.md ] || fail "missing Pi handout prompt"
[ -f .pi/agent/prompts/distill.md ] || fail "missing Pi distill prompt"
[ -f .pi/agent/prompts/enrich-blueprint.md ] || fail "missing Pi enrich-blueprint prompt"
[ -f .agents/skills/enrich-blueprint/SKILL.md ] || fail "missing enrich-blueprint skill"
[ -f .agents/blueprints/CLI.md ] || fail "missing CLI blueprint"
[ ! -e agents ] || fail "project blueprints must live under .agents/blueprints"

require_relative_link .codex/AGENTS.md ../.agents/AGENTS.md
require_relative_link .config/opencode/AGENTS.md ../../.agents/AGENTS.md
require_relative_link .claude/skills ../.agents/skills
require_relative_link .pi/agent/AGENTS.md ../../.agents/AGENTS.md
require_relative_link .codex/skills/bonsai ../../.agents/skills/bonsai
require_relative_link .config/opencode/skills/bonsai ../../../.agents/skills/bonsai
require_relative_link .pi/agent/skills/bonsai ../../../.agents/skills/bonsai
git check-ignore -q --no-index .memories ||
  fail "per-project memory symlinks must be ignored globally"
git check-ignore -q --no-index .handouts/example.md ||
  fail "project handouts must be ignored globally"
git check-ignore -q --no-index .agents/memories/example/MEMORY.md ||
  fail "physical project memory must remain local"
git check-ignore -q --no-index .agents/memories.codex-native-legacy/MEMORY.md ||
  fail "legacy memory archives must remain local"
if git check-ignore -q --no-index .codex/hooks.json; then
  fail "tracked Codex hooks are still ignored"
fi
rg -F 'Name every branch you create `ab/<slug>`' .agents/AGENTS.md >/dev/null ||
  fail "global agent guidance must require ab/<slug> branch names"
rg -F '`commit/push` means run `commit`, then `push`' .agents/AGENTS.md >/dev/null ||
  fail "global agent guidance must compose slash-separated Git workflows"
rg -F 'The `pullrequest` skill is explicitly end-to-end' .agents/AGENTS.md >/dev/null ||
  fail "global agent guidance must define pullrequest as a one-shot workflow"
rg -F 'Never add `Co-Authored-By`' .agents/AGENTS.md >/dev/null ||
  fail "global agent guidance must forbid harness authorship trailers"
rg -F 'Never add `Co-Authored-By`' .pi/agent/APPEND_SYSTEM.md >/dev/null ||
  fail "Pi adapter must forbid harness authorship trailers"
rg -F 'Never add `Co-Authored-By`' .config/opencode/attribution.md >/dev/null ||
  fail "OpenCode must load a no-attribution instruction file"
rg -F 'canonical local project memory' .agents/AGENTS.md >/dev/null ||
  fail "global agent guidance must define the shared project-memory location"
rg -Fx '  codex features enable hooks' setup.sh >/dev/null ||
  fail "setup must enable tracked Codex hooks"
rg -Fx '  codex features disable memories' setup.sh >/dev/null ||
  fail "setup must disable Codex native memory in favor of shared project memory"
rg -F 'memories.codex-native-legacy' setup.sh >/dev/null ||
  fail "setup must preserve the legacy nested memory repository"
rg -F 'scripts/configure-codex-hooks.mjs' setup.sh >/dev/null ||
  fail "setup must configure Codex hook trust through the app server"
rg -F "\\! -name '.memories'" setup.sh >/dev/null ||
  fail "setup must not link generated project memory into the home directory"
rg -F "\\! -name '.handouts'" setup.sh >/dev/null ||
  fail "setup must not link project handouts into the home directory"
rg -F '[Conventional Commits specification](https://www.conventionalcommits.org/)' AGENTS.md >/dev/null ||
  fail "AGENTS.md must require the latest Conventional Commits specification"
for commit_skill in .agents/skills/commit/SKILL.md .agents/skills/squash/SKILL.md .agents/skills/pullrequest/SKILL.md; do
  rg -F 'MUST follow the latest published [Conventional Commits specification](https://www.conventionalcommits.org/)' "$commit_skill" >/dev/null ||
    fail "$commit_skill must enforce the latest Conventional Commits specification"
done
rg -F 'Do not stage files or create, amend, squash, or otherwise rewrite commits' .agents/skills/push/SKILL.md >/dev/null ||
  fail "push skill must not stage or create commits"
rg -F 'Require a clean worktree and index' .agents/skills/squash/SKILL.md >/dev/null ||
  fail "squash skill must reject pending worktree changes"
rg -F 'This is the complete pull-request workflow. Invoke it once' .agents/skills/pullrequest/SKILL.md >/dev/null ||
  fail "pullrequest skill must be a one-shot state-driven workflow"
rg -F 'git merge --no-commit' .agents/skills/pullrequest/SKILL.md >/dev/null ||
  fail "pullrequest skill must merge the latest PR base into the current branch"
rg -F 'conversation comments, review summaries, and GraphQL' .agents/skills/pullrequest/SKILL.md >/dev/null ||
  fail "pullrequest skill must inspect conversation, review, and inline feedback"
rg -F 'resolveReviewThread' .agents/skills/pullrequest/SKILL.md >/dev/null ||
  fail "pullrequest skill must resolve inline threads only after addressing them"
rg -F 'Finish only when local HEAD equals the PR head' .agents/skills/pullrequest/SKILL.md >/dev/null ||
  fail "pullrequest skill must converge PR head, base freshness, feedback, and CI"
rg -F 'Never stage or commit handouts' .agents/skills/handout/SKILL.md >/dev/null ||
  fail "handout skill must keep handouts out of repository history"
rg -F 'applicable `AGENTS.md`' .agents/skills/distill/SKILL.md >/dev/null ||
  fail "distill skill must write harness-neutral AGENTS.md guidance"
rg -F 'client-specific memory or state directory' .agents/skills/distill/SKILL.md >/dev/null ||
  fail "distill skill must reject client-specific memory stores"
rg -F 'Stay in plan mode' .agents/skills/enrich-blueprint/SKILL.md >/dev/null ||
  fail "enrich-blueprint skill must stay in plan mode"
rg -F 'Ask which candidates to include' .agents/skills/enrich-blueprint/SKILL.md >/dev/null ||
  fail "enrich-blueprint skill must ask which project conventions to include"
rg -F 'stack and language manifests' .agents/skills/enrich-blueprint/SKILL.md >/dev/null ||
  fail "enrich-blueprint skill must survey the project stack"
rg -F 'CI workflows' .agents/skills/enrich-blueprint/SKILL.md >/dev/null ||
  fail "enrich-blueprint skill must survey CI"
rg -F 'README' .agents/skills/enrich-blueprint/SKILL.md >/dev/null ||
  fail "enrich-blueprint skill must survey the README"
rg -F 'direct dependencies' .agents/skills/enrich-blueprint/SKILL.md >/dev/null ||
  fail "enrich-blueprint skill must survey dependencies"
for shared_skill in .agents/skills/*/SKILL.md; do
  if rg -n 'Codex|Claude|OpenCode|CODEX_HOME|CLAUDE_PROJECT_DIR|\$ARGUMENTS|disallowed-tools|allowed-tools' "$shared_skill" >/dev/null; then
    fail "$shared_skill contains harness-specific instructions"
  fi
done
rg -Fx 'export OPENCODE_DISABLE_CLAUDE_CODE=1' .zshenv >/dev/null ||
  fail "OpenCode must ignore Claude compatibility paths"
rg -Fx 'export PI_SKIP_VERSION_CHECK=1' .zshenv >/dev/null ||
  fail "mise must own Pi updates"
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
rg -Fx 'set -g mouse on' .tmux.conf >/dev/null ||
  fail "tmux must forward mouse events to full-screen agent TUIs"
rg -F "WheelUpPane if -F '#{||:#{pane_in_mode},#{mouse_any_flag}}'" .tmux.conf >/dev/null ||
  fail "tmux wheel-up must use copy-mode when the pane does not capture the mouse"
rg -F "WheelDownPane if -F '#{||:#{pane_in_mode},#{mouse_any_flag}}'" .tmux.conf >/dev/null ||
  fail "tmux wheel-down must stay with the active mouse owner"
if rg -n 'Wheel(Up|Down)Pane.*@agent-kind|send-keys C-t' .tmux.conf >/dev/null; then
  fail "tmux wheel routing must not depend on application identity or shortcuts"
fi
rg -Fx 'set -s extended-keys on' .tmux.conf >/dev/null ||
  fail "tmux must preserve extended keys for agent TUIs"
rg -Fx 'set -g extended-keys-format csi-u' .tmux.conf >/dev/null ||
  fail "tmux must encode extended keys with CSI-u for Pi"
rg -F 'alacritty:extkeys' .tmux.conf >/dev/null ||
  fail "tmux must advertise Alacritty extended-key support"
rg -Fx 'set -g allow-passthrough on' .tmux.conf >/dev/null ||
  fail "tmux must pass supported agent TUI terminal sequences through"
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
rg -F '#{s/^OC [|] //:pane_title}' .tmux.conf >/dev/null ||
  fail "tmux pane borders must remove OpenCode's redundant title prefix"
rg -F '#{m/r:^(OC [|] |OpenCode$),#{pane_title}}' .tmux.conf >/dev/null ||
  fail "tmux pane borders must prioritize native OpenCode titles over stale agent state"
rg -F '#{s/^PI [|] //:pane_title}' .tmux.conf >/dev/null ||
  fail "tmux pane borders must render Pi session titles"
[ "$(rg -c '^bind -r [HJKL] if -F' .tmux.conf)" -eq 4 ] ||
  fail "prefix+H/J/K/L must move panes left/down/up/right"
[ "$(rg -c 'move-pane .* -s \. -t .*previous' .tmux.conf)" -eq 4 ] ||
  fail "directional pane movement must re-tile panes when changing axes"
[ "$(rg -c 'swap-pane -d -t .*-(of)' .tmux.conf)" -eq 4 ] ||
  fail "directional pane movement must swap existing geometric neighbors"
rg -F '#{>=:#{pane_height},#{e|-:#{window_height},1}}' .tmux.conf >/dev/null ||
  fail "vertical pane movement must account for tmux border rows"
rg -F '#{>=:#{pane_width},#{e|-:#{window_width},1}}' .tmux.conf >/dev/null ||
  fail "horizontal pane movement must account for tmux scrollbar columns"
[ "$(rg -c '^bind -T copy-mode-vi (escape|q|C-c) if-shell -F' .tmux.conf)" -eq 3 ] ||
  fail "OpenCode copy-mode exits must force a tmux client redraw"
if rg -n '^bind J choose-tree' .tmux.conf >/dev/null; then
  fail "prefix+J must move the active pane, not open the join-pane picker"
fi
[ -f .pi/agent/extensions/tmux-title.ts ] || fail "missing Pi tmux title extension"
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
[ ! -e scripts/tmux-resurrect-save.sh ] || fail "tmux process/content save wrapper remains"
rg -Fx "set -g @resurrect-processes 'false'" .tmux.conf >/dev/null ||
  fail "tmux restore must start fresh shell processes"
if rg -n '@resurrect-capture-pane-contents|@resurrect-pane-contents-area|@resurrect-save-script-path' .tmux.conf >/dev/null; then
  fail "tmux restore must not capture pane content"
fi
if rg -n 'tmuxinator|headquarter|beside|session-picker' .tmux.conf scripts/status-click.sh >/dev/null; then
  fail "retired named-session routing remains configured"
fi

tmux_socket="dotfiles-check-$$"
cleanup_tmux() {
  tmux -L "$tmux_socket" kill-server >/dev/null 2>&1 || true
}
trap cleanup_tmux EXIT
tmux -L "$tmux_socket" -f /dev/null new-session -d -s check
tmux_default_keys=$(tmux -L "$tmux_socket" list-keys -T prefix)
for window_index in 1 2 9; do
  printf '%s\n' "$tmux_default_keys" |
    rg -F "select-window -t :=$window_index" >/dev/null ||
    fail "tmux default prefix+$window_index mapping is unavailable"
done
tmux -L "$tmux_socket" source-file -n .tmux.conf >/dev/null
cleanup_tmux
trap - EXIT

printf '\nAll checks passed.\n'
