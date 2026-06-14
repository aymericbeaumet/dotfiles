# Platform

This repo targets **macOS (primary)** and **Debian/Ubuntu Linux (supported)**. Default to portable solutions; gate macOS-only code explicitly.

## Tool installation order

1. **mise** — preferred. Cross-platform binaries live in `.config/mise/config.toml`. Use the mise registry shortname; fall back to explicit `aqua:owner/repo`, `ubi:owner/repo`, `npm:pkg`, or `pipx:pkg` backends when needed.
2. **Homebrew (`Brewfile`)** — macOS-only software only: GUI apps/casks and macOS-only tools such as Mole. `setup.sh` must never run `brew bundle` on Linux.
3. **setup.sh package lists** — bootstrappers and system-level deps only (`mise`, `zsh`, `build-essential`, `wireguard-tools`, etc.).

**Do not** suggest `cargo install` or `go install` for user-facing CLI tools. mise handles those backends if truly needed.

## What's macOS-only

- `setup.sh` "SETUP MACOS" block (`defaults write`, `killall Dock`) — auto-skipped on non-darwin via `uname -s`.
- `.hammerspoon/`, `.config/karabiner/`, `.config/flash/`, `.config/alacritty/` — may be symlinked on Linux, but macOS-only commands must be gated before execution.
- `Brewfile` — macOS-only software list. Do not put cross-platform user-facing CLIs or Linux packages in it.
- `scripts/toggle_sleep.sh`, `scripts/toggle_mute.sh`, `scripts/toggle_wifi.sh` — call `caffeinate`/`osascript`/`networksetup`. Linux equivalents not implemented.

## Cross-platform helpers (use these, don't inline `pbcopy`/`open`)

| Helper | Purpose | Detection order |
|---|---|---|
| `scripts/clip.sh` | Write stdin to system clipboard | `pbcopy` → `wl-copy` (Wayland) → `xclip` → `xsel` |
| `scripts/open-url.sh` | Open URL/file in default app | `open` (macOS) → `xdg-open` (graphical Linux) → `$BROWSER`/`w3m`/`elinks`/`links`/`lynx` (headless Linux) |

When adding tmux bindings or scripts that touch the clipboard or open URLs, route through these rather than calling `pbcopy`/`open` directly.

## OS-gating pattern

```bash
if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS-only
fi
```

```bash
if command -v apt-get >/dev/null 2>&1; then
  # Debian/Ubuntu only
fi
```

Prefer feature detection (`command -v`) over OS sniffing whenever possible.

## Notable bug history

- `setup.sh` previously used `find -type file/dir/link` (invalid for both GNU and BSD find). Fixed to `f`/`d`/`l`. If you see similar typos elsewhere, treat as a bug.
