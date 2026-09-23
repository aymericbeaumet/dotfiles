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

for command_name in actionlint git jq node nvim rg shellcheck shfmt stylua taplo tmux yq zsh; do
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
  [ -f "$json_file" ] || continue
  jq empty "$json_file"
done < <(git ls-files '*.json')

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
    any(contains("scripts/agent-pane-idle.sh clear claude"))) and
  ([.hooks[][]?.hooks[]?.command] |
    all(test("scripts/(claude-retry|format-on-save)\\.sh") | not))
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
  any(.bindings[]; .context == "Chat" and .bindings."ctrl+t" == "chat:modelPicker") and
  any(.bindings[]; .context == "ModelPicker" and .bindings."ctrl+t" == "modelPicker:increaseEffort")
' .claude/keybindings.json >/dev/null

jq -e '
  (.hooks | keys) == ["PreToolUse", "SessionStart", "Stop", "UserPromptSubmit"] and
  any(.hooks.PreToolUse[]?.hooks[]?; .command | contains("scripts/worktree-guard.sh")) and
  any(.hooks.SessionStart[]?.hooks[]?; .command | contains("scripts/agent-pane-idle.sh clear codex")) and
  any(.hooks.UserPromptSubmit[]?.hooks[]?; .command | contains("scripts/agent-pane-idle.sh busy")) and
  any(.hooks.Stop[]?.hooks[]?; .command | contains("scripts/agent-pane-idle.sh idle")) and
  any(.hooks.Stop[]?.hooks[]?; .command | contains("scripts/agent-pane-title.sh codex"))
' .codex/hooks.json >/dev/null

[ -x scripts/worktree-guard.sh ] || fail "worktree guard must be executable"
[ -x scripts/configure-codex-hooks.mjs ] || fail "Codex hook configurator must be executable"
node --check scripts/configure-codex-hooks.mjs
rg -F 'command codex --dangerously-bypass-hook-trust "$@"' .zshrc >/dev/null ||
  fail "interactive Codex must bypass hook trust prompts"

check_hn_status() (
  test_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hn-check.XXXXXX") || exit 1
  trap 'rm -rf "$test_root"' EXIT INT TERM
  mkdir -p "$test_root/items"

  reader_preview=$(printf '%s\n' \
    'Title: Publisher title' \
    'URL Source: https://example.com/story' \
    '' \
    'Markdown Content:' \
    'Actual first paragraph from the article.' |
    python3 scripts/hn-article-preview.py --max-chars 80)
  [ "$reader_preview" = 'Actual first paragraph from the article.' ] ||
    fail "HN reader fallback must omit transport metadata: $reader_preview"

  printf '%s\n' \
    '{"id":101,"by":"alice","score":42,"descendants":7,"title":"News #[fg=red] trick","url":"https://example.com/story"}' \
    >"$test_root/items/101.json"
  printf '%s\n' \
    '<html><body><nav>Skip navigation</nav><article>First paragraph from the article. Second paragraph remains readable.<script>ignore me</script></article></body></html>' \
    >"$test_root/article.html"

  TMPDIR="$test_root" HN_REFRESH=1 HN_TEST_TOP_IDS=101 \
    HN_TEST_ITEMS_DIR="$test_root/items" \
    HN_TEST_ARTICLE_HTML_FILE="$test_root/article.html" \
    HN_STORIES_COUNT=1 HN_PREVIEW_MAX_CHARS=50 \
    scripts/hn-top-stories.sh
  output=$(command cat "$test_root/flash-hn-top-stories/rendered-v5.txt")
  [ "$(printf '%s\n' "$output" | awk 'END { print NR }')" -eq 1 ] ||
    fail "HN carousel entries must remain one physical line each"
  printf '%s' "$output" | rg -F '#[popup=inline:' >/dev/null ||
    fail "HN carousel row must carry its popup body atomically"
  printf '%s' "$output" | rg -F '#[link=https://news.ycombinator.com/item?id=101]' >/dev/null ||
    fail "HN carousel must preserve the discussion link"
  printf '%s' "$output" | rg -F '#[link=https://example.com/story]' >/dev/null ||
    fail "HN carousel must preserve the article link"
  printf '%s' "$output" | rg -F '#[nopopup]' >/dev/null ||
    fail "HN carousel popup span must be balanced"
  encoded=$(printf '%s' "$output" | sed -n 's/^#\[popup=inline:\([^]]*\)\].*/\1/p')
  decoded=$(printf '%s' "$encoded" |
    python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()), end="")')
  printf '%s' "$decoded" | rg -F 'First paragraph from the article.' >/dev/null ||
    fail "HN popup must contain extracted article text: $decoded"
  if printf '%s' "$decoded" | rg -q '^By .* points'; then
    fail "HN popup must never substitute story metadata for article content: $decoded"
  fi
  printf '%s' "$decoded" | rg -F 'News ##[fg=red] trick' >/dev/null ||
    fail "HN popup must escape marker-looking article data: $decoded"
  [ "${#decoded}" -lt 180 ] || fail "HN popup preview must honor its configured character cap"

  TMPDIR="$test_root" HN_REFRESH=1 HN_TEST_TOP_IDS=101 \
    HN_TEST_ITEMS_DIR="$test_root/items" \
    HN_TEST_ARTICLE_HTML_FILE="$test_root/missing.html" \
    HN_STORIES_COUNT=1 HN_PREVIEW_MAX_CHARS=50 \
    scripts/hn-top-stories.sh
  output=$(command cat "$test_root/flash-hn-top-stories/rendered-v5.txt")
  encoded=$(printf '%s' "$output" | sed -n 's/^#\[popup=inline:\([^]]*\)\].*/\1/p')
  decoded=$(printf '%s' "$encoded" |
    python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()), end="")')
  printf '%s' "$decoded" | rg -F 'First paragraph from the article.' >/dev/null ||
    fail "HN popup must retain a stale per-story preview after a fetch failure: $decoded"

  printf '%s\n' \
    '{"id":102,"by":"bob","score":3,"descendants":2,"title":"Ask HN: test","text":"<p>Self-post body is available without fetching an article.</p>"}' \
    >"$test_root/items/102.json"
  TMPDIR="$test_root" HN_REFRESH=1 HN_TEST_TOP_IDS=102 \
    HN_TEST_ITEMS_DIR="$test_root/items" HN_STORIES_COUNT=1 \
    scripts/hn-top-stories.sh
  output=$(command cat "$test_root/flash-hn-top-stories/rendered-v5.txt")
  encoded=$(printf '%s' "$output" | sed -n 's/^#\[popup=inline:\([^]]*\)\].*/\1/p')
  decoded=$(printf '%s' "$encoded" |
    python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()), end="")')
  printf '%s' "$decoded" | rg -F 'Self-post body is available' >/dev/null ||
    fail "HN self-post popup must use the item body: $decoded"

  cache_root="$test_root/cache-only/flash-hn-top-stories"
  mkdir -p "$cache_root" "$test_root/fake-bin"
  printf '%s\n' 'cached carousel row' >"$cache_root/rendered-v5.txt"
  printf '%s\n' '#!/bin/sh' 'touch "${HN_NETWORK_MARKER:?}"' 'exit 1' \
    >"$test_root/fake-bin/curl"
  chmod +x "$test_root/fake-bin/curl"
  output=$(PATH="$test_root/fake-bin:$PATH" TMPDIR="$test_root/cache-only" \
    HN_NETWORK_MARKER="$test_root/network-called" HN_RENDER_TTL_SECONDS=3600 \
    scripts/hn-top-stories.sh)
  [ "$output" = 'cached carousel row' ] || fail "HN must serve its rendered cache unchanged"
  [ ! -e "$test_root/network-called" ] || fail "fresh HN cache must never perform network work"
)
check_hn_status

check_flash_status() (
  config=$(yq -p toml -o json '.' .config/flash/flash.toml)
  printf '%s' "$config" | jq -e '
    . as $config |
    all(["claude", "codex"][];
      . as $name |
      ($config.statusbar.options["@right"] |
        contains("#{flash.plugin.aiproviders.\($name)_label}")) and
      $config.statusbar.popup[$name] == "#{flash.plugin.aiproviders.\($name)_details}")
  ' >/dev/null || fail "Flash provider labels and popups must use aiproviders-owned content"
  if printf '%s' "$config" | jq -e '
    [.. | strings] | any(test("#\\[popup=ai\\]|(?:plugin:|flash\\.plugin\\.)aiproviders\\.(?:claude|fable|codex)_usage|agent-quota-status\\.sh"))
  ' >/dev/null; then
    fail "dotfiles must not assemble or fetch AI provider status outside aiproviders"
  fi
  printf '%s' "$config" | jq -e '
    .plugin.feed.label == "aggr" and
    .plugin.feed.url == "https://aggr.aymericbeaumet.com/rss.xml" and
    (.statusbar.options["@left"] |
      contains("#[link=https://aggr.aymericbeaumet.com]#{flash.plugin.feed.summary}#[nolink]"))
  ' >/dev/null || fail "aggr must link its label to the homepage and fetch its RSS feed"
  printf '%s' "$config" | jq -e '
    (.statusbar.options["@centre"] |
      capture("#\\[popup=active-app\\]#\\{=/(?<width>[0-9]+)/…:flash\\.active_app_name\\}#\\[nopopup\\]") |
      .width | tonumber | . > 0 and . <= 24) and
    (.statusbar.popup["active-app"] | contains("#{flash.plugin.processes.focused_app_details}"))
  ' >/dev/null || fail "Flash must bound the active-app label and retain focused-process details"
  printf '%s' "$config" | jq -e '
    . as $config |
    all(["cpu", "memory", "disks", "network", "power"][];
      $config.plugin[.].summary_mode == "compact") and
    all(["cpu", "memory", "disks", "network", "battery"][];
      . as $name |
      (if $name == "battery" then "power" else $name end) as $plugin |
      ($config.statusbar.options["@right"] | contains("#[popup=\($name)]")) and
      ($config.statusbar.options["@right"] | contains("#{flash.plugin.\($plugin).label}")) and
      $config.statusbar.popup[$name] == "#{flash.plugin.\($plugin).details}") and
    ($config.statusbar.options["@right"] | contains("#[popup=date]")) and
    $config.statusbar.popup.date == "#{flash.calendar}" and
    ($config.terminal | has("date") | not)
  ' >/dev/null || fail "Flash monitor popups must use plugin details and the built-in calendar popup"
  printf '%s' "$config" | jq -e '
    . as $config |
    [.statusbar.template, .statusbar.options[], .statusbar.popup[]] |
    all(.[];
      ([scan("#\\[popup=[^]]+\\]")] | length) ==
      ([scan("#\\[nopopup\\]")] | length)) and
    all(.[] | scan("#\\[popup=([^]]+)\\]") | .[0];
      . as $name |
      startswith("inline:") or
      ($config.statusbar.popup[$name] | type == "string") or
      ($config.terminal[$name].command | type == "array"))
  ' >/dev/null || fail "Flash popup markers must be balanced and point to defined content or terminals"
  while IFS=$'\t' read -r flag config_path; do
    [ -n "$config_path" ] && [ -e ".config/flash/$config_path" ] ||
      fail "Flash terminal configuration does not exist: $config_path"
    if [ "$flag" = '-C' ]; then
      [ -s ".config/flash/$config_path/conf" ] && [ -s ".config/flash/$config_path/keys" ] ||
        fail "Flash calendar configuration must include settings and key bindings"
    fi
  done < <(printf '%s' "$config" | jq -r '
    .terminal[] | select(.command[0] == "btm" or .command[0] == "calcurse") |
    .command as $args | range(0; $args | length) as $i |
    select(["--config_location", "-D", "-C"] | index($args[$i])) |
    [$args[$i], $args[$i + 1]] | @tsv
  ')
)
check_flash_status
rg -F '#[popup=inline:' scripts/hn-top-stories.sh >/dev/null ||
  fail "HN carousel rows must carry their own popup details"
awk '
  $0 == "[mode.all.mappings]" { in_all = 1; next }
  in_all && /^\[/ { exit }
  in_all && $0 == "\"alt+z\" = [\"flash\", \"window_move\", \"--x=10.6925%\", \"--y=10.6925%\", \"--width=78.615%\", \"--height=78.615%\"]" { found = 1 }
  END { exit found ? 0 : 1 }
' .config/flash/flash.toml ||
  fail "Flash all-mode mappings must map alt+z to a centered golden-area layout"

rg -Fx 'bottom = "latest"' .config/mise/config.toml >/dev/null ||
  fail "Bottom must be installed through mise"
rg -Fx 'yq = "4.53.3"' .config/mise/config.toml >/dev/null ||
  fail "yq must be installed through mise"
rg -Fx 'alias htop=btm' .zshrc >/dev/null ||
  fail "htop must invoke the mise-managed Bottom CLI"
rg -F '"$CLAUDE_MISE_ROOT/node_modules/@anthropic-ai/claude-code/install.cjs"' setup.sh >/dev/null ||
  fail "Claude postinstall repair must support mise's aube npm layout"
rg -F '"$CLAUDE_MISE_ROOT/lib/node_modules/@anthropic-ai/claude-code/install.cjs"' setup.sh >/dev/null ||
  fail "Claude postinstall repair must support mise's legacy npm layout"

yq -p toml -o json '.' .config/mise/config.toml | jq -e '
  (.tools | has("aqua:anomalyco/opencode") | not) and
  (.tools | has("npm:@earendil-works/pi-coding-agent") | not) and
  (.tools | has("pipx") | not) and
  .tools."pipx:semble".version == "0.5.4" and
  .tools."pipx:semble".uvx == true and
  (.tools | has("uv"))
' >/dev/null || fail "Semble must use uv and retired agents must not be provisioned"
for retired_state in .config/opencode/example-state .pi/example-state; do
  git check-ignore -q --no-index "$retired_state" ||
    fail "retired agent state must remain private: $retired_state"
done

toml_files=()
while IFS= read -r toml_file; do
  [ -f "$toml_file" ] || continue
  toml_files+=("$toml_file")
done < <(git ls-files '*.toml')
taplo check "${toml_files[@]}"
stylua --check .config/nvim scripts/check-neovim.lua
nvim --headless -u NONE -n -i NONE -l scripts/check-neovim.lua
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
[ -f .agents/skills/blueprint/SKILL.md ] || fail "missing blueprint skill"
[ -f .agents/blueprints/CLI.md ] || fail "missing CLI blueprint"
[ ! -e agents ] || fail "project blueprints must live under .agents/blueprints"

require_relative_link .codex/AGENTS.md ../.agents/AGENTS.md
require_relative_link .claude/skills ../.agents/skills
require_relative_link .codex/skills/bonsai ../../.agents/skills/bonsai
if git check-ignore -q --no-index .memories; then
  fail "obsolete per-project memory paths must not be ignored"
fi
git check-ignore -q --no-index .handouts/example.md ||
  fail "project handouts must be ignored globally"
git check-ignore -q --no-index .agents/memories/example/legacy.txt ||
  fail "legacy project memory must remain local"
git check-ignore -q --no-index .agents/memories.codex-native-legacy/legacy.txt ||
  fail "legacy memory archives must remain local"
if git check-ignore -q --no-index .codex/hooks.json; then
  fail "tracked Codex hooks are still ignored"
fi
[ ! -e scripts/project-memory.sh ] || fail "obsolete project-memory adapter remains"
if rg -q 'scripts/project-memory\.sh|extensions/project-memory\.ts' \
  .codex/hooks.json .claude/settings.json; then
  fail "client configuration still loads an obsolete project-memory adapter"
fi
rg -Fx '  codex features enable hooks' setup.sh >/dev/null ||
  fail "setup must enable tracked Codex hooks"
rg -Fx '  codex features disable memories' setup.sh >/dev/null ||
  fail "setup must disable Codex native memory in favor of committed project docs"
rg -F 'scripts/configure-codex-hooks.mjs' setup.sh >/dev/null ||
  fail "setup must configure Codex hook trust through the app server"
rg -F "\\! -name '.memories'" setup.sh >/dev/null ||
  fail "setup must not link obsolete project memory into the home directory"
rg -F "\\! -name '.handouts'" setup.sh >/dev/null ||
  fail "setup must not link project handouts into the home directory"
for shared_skill in .agents/skills/*/SKILL.md; do
  if rg -n 'Codex|Claude|OpenCode|CODEX_HOME|CLAUDE_PROJECT_DIR|\$ARGUMENTS|disallowed-tools|allowed-tools' "$shared_skill" >/dev/null; then
    fail "$shared_skill contains harness-specific instructions"
  fi
done
rg -Fx 'setopt SHARE_HISTORY' .zshrc >/dev/null ||
  fail "Zsh tabs must share history live"
rg -Fx 'unsetopt APPEND_HISTORY INC_APPEND_HISTORY' .zshrc >/dev/null ||
  fail "Zsh shared history must own incremental writes"
rg -F 'exec \"$HOME/.dotfiles/scripts/scratch-terminal.sh\""]' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty must attach its single window to the local scratch session"
if rg -n 'ipc_socket|create-window|ALACRITTY_SOCKET|mosh|moria' .config/alacritty/alacritty.toml scripts/scratch-terminal.sh >/dev/null; then
  fail "the remote Moria scratch window was retired; Alacritty runs one local window"
fi
alacritty_binding_action() {
  awk -v key="$1" -v mods="$2" '
    /^\[\[keyboard.bindings\]\]$/ { action = ""; k = ""; m = ""; next }
    /^action = / { action = $0 }
    /^key = / { k = $0 }
    /^mods = / {
      m = $0
      if (k == "key = \"" key "\"" && m == "mods = \"" mods "\"") print action
    }
  ' .config/alacritty/alacritty.toml
}
[ "$(alacritty_binding_action W 'Command|Shift')" = 'action = "Quit"' ] ||
  fail "Alacritty Cmd+Shift+W must close the single window by quitting"
[ "$(alacritty_binding_action Q Command)" = 'action = "Quit"' ] ||
  fail "Alacritty Cmd+Q must quit"
rg -Fx 'chars = "\u0011x"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+W must kill the tmux pane"
if rg -n '^bind [0-9]' .tmux.conf >/dev/null; then
  fail "numeric window selection must use tmux's built-in mappings"
fi
rg -Fx 'chars = "\u0011\u0031"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+1 must emit tmux prefix+1"
if [[ "$(rg -Fxc 'chars = "\u0011p"' .config/alacritty/alacritty.toml)" -ne 2 ]]; then
  fail "Alacritty Cmd+Shift+{ must handle both shifted-bracket key forms"
fi
if [[ "$(rg -Fxc 'chars = "\u0011n"' .config/alacritty/alacritty.toml)" -ne 2 ]]; then
  fail "Alacritty Cmd+Shift+} must handle both shifted-bracket key forms"
fi
rg -Fx 'key = "{"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+Shift+{ must bind the resulting brace"
rg -Fx 'key = "}"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+Shift+} must bind the resulting brace"
rg -Fx 'bind -r p previous-window' .tmux.conf >/dev/null ||
  fail "tmux must expose previous-window navigation to Alacritty"
rg -Fx 'bind -r n next-window' .tmux.conf >/dev/null ||
  fail "tmux must expose next-window navigation to Alacritty"
rg -Fx 'chars = "\u0011O"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+[ must select the previous tmux pane"
rg -Fx 'chars = "\u0011o"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+] must select the next tmux pane"
rg -Fx 'chars = "\u0011v"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+D must split the tmux pane vertically"
rg -Fx 'chars = "\u0011s"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+Shift+D must split the tmux pane horizontally"
rg -Fx 'bind      o select-pane -t :.+' .tmux.conf >/dev/null ||
  fail "tmux must expose next-pane navigation to Alacritty"
rg -Fx 'bind      O select-pane -t :.-' .tmux.conf >/dev/null ||
  fail "tmux must expose previous-pane navigation to Alacritty"
rg -Fx 'chars = "\u0011d"' .config/alacritty/alacritty.toml >/dev/null ||
  fail "Alacritty Cmd+R must ask tmux to detach cleanly"
for shifted_arrow in 'B:D' 'F:C' 'N:B' 'P:A'; do
  key=${shifted_arrow%%:*}
  arrow=${shifted_arrow##*:}
  awk -v key="$key" -v arrow="$arrow" '
    /^\[\[keyboard.bindings\]\]$/ { chars = ""; k = ""; mods = ""; next }
    /^chars = / { chars = $0 }
    /^key = / { k = $0 }
    /^mods = / {
      mods = $0
      if (chars == "chars = \"\\u001b[1;2" arrow "\"" && k == "key = \"" key "\"" && mods == "mods = \"Control|Shift\"") found = 1
    }
    END { exit !found }
  ' .config/alacritty/alacritty.toml ||
    fail "Alacritty Ctrl+Shift+$key must send Shift+arrow ($arrow) for terminal TUIs"
done
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
  fail "tmux must encode extended keys with CSI-u for agent TUIs"
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
if rg -n '^bind J choose-tree' .tmux.conf >/dev/null; then
  fail "prefix+J must move the active pane, not open the join-pane picker"
fi
if rg -n 'user-keys|bind -n User' .tmux.conf >/dev/null; then
  fail "Alacritty shortcuts must use normal tmux prefix mappings"
fi
rg -F 'tmux new-session -A -s "$LOCAL_SESSION" -c "$LOCAL_ROOT"' scripts/scratch-terminal.sh >/dev/null ||
  fail "scratch terminal must reattach the local tmux session"
[ ! -e scripts/grid.sh ] || fail "retired tmux grid helper remains"
if rg -n 'grid\.sh|rows=3|cols=3' .tmux.conf >/dev/null; then
  fail "retired tmux grid mappings remain"
fi
if rg -n 'mosh' Brewfile >/dev/null; then
  fail "Mosh was retired with the Moria scratch window"
fi
[ ! -e .config/tmuxinator ] || fail "retired tmuxinator profiles remain"
[ ! -e scripts/tmux-resurrect-save.sh ] || fail "tmux process/content save wrapper remains"
rg -Fx "set -g @resurrect-default-processes 'false'" .tmux.conf >/dev/null ||
  fail "tmux restore must not relaunch default non-agent processes"
rg -Fx "set -g @resurrect-processes '\"~codex->codex --dangerously-bypass-hook-trust\" \"~claude->claude\"'" .tmux.conf >/dev/null ||
  fail "tmux restore must relaunch only Codex and Claude through stable commands"
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
