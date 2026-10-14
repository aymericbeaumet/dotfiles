# Zsh performance

The shell should feel like a bare zsh in xterm. Two numbers matter, and
`scripts/zsh-latency.sh [dir]` measures both inside a real interactive shell:

| Measurement                              | Before  | Now     |
| ---------------------------------------- | ------- | ------- |
| Enter to editable prompt (median)        | 33 ms   | 2 ms    |
| `cd` to editable prompt (median)         | 20 ms   | 2 ms    |
| Login shell start (`zsh -l -i -c exit`)  | 160 ms  | 100 ms  |

The first is what makes a prompt feel laggy: every precmd hook runs between a
command finishing and the next prompt accepting keys. Forking a process on an
M4 costs about 1 ms, and each tool binary adds its own startup on top.

## Rules

- **Nothing spawns a process before every prompt.** Hooks that need a tool run
  it on a directory change or after a relevant command instead. The current
  precmd list is p10k, `_reset_cursor`, `_title_precmd`, and
  `_dotfiles_mise_precmd`, all under 0.1 ms. `scripts/check.sh` guards the
  known offenders.
- **Hooks write to the terminal descriptor, never stdout.** p10k's instant
  prompt redirects stdout into a capture file and only restores it in its own
  precmd, which it keeps last. Bytes written by earlier hooks are replayed as
  "console output during zsh initialization" unless p10k recognises them. It
  whitelists cursor-shape and OSC sequences but not the `\e[?1000l` mouse-mode
  resets. `.zshrc` opens `/dev/tty` once (`sysopen`, close-on-exec) and
  `_tty_print` writes there; reopening the device costs about a millisecond per
  write on macOS.
- **Tool integrations load from a cache.** `_dotfiles_cached_source <name>
  <binary> <generator...>` (defined in `.zshenv` so `.zprofile` can use it)
  stores the generator's output under `${XDG_CACHE_HOME:-~/.cache}/zsh/<name>.zsh`
  with the generator command line as its first line. It regenerates when the
  binary is newer than the cache or the command line changed, so flags and
  environment belong in the generator (`env CARAPACE_EXCLUDES=... carapace ...`).
  Cached today: `brew shellenv`, `fzf --zsh`, `mise activate zsh`, `zoxide init`,
  carapace, and bonsai. Delete the files to force a rebuild. `source` ignores
  `.zwc` siblings, so the caches are plain files.
- **zsh-autosuggestions binds once.** `ZSH_AUTOSUGGEST_MANUAL_REBIND=1` stops it
  rewrapping all 700 widgets before each prompt (7 ms). Any plugin that defines
  widgets (fzf, fzf-git.sh) must therefore load before it in the turbo list.
- **zoxide hooks `chpwd`, not the prompt.** `--hook=pwd` runs `zoxide add` on a
  directory change only.
- **mise refreshes on directory change or after mise commands.** Its stock
  precmd hook ran `mise hook-env` before every prompt (12 ms). `_dotfiles_mise_init`
  removes that hook and refreshes at the next prompt only after a command line
  mentioning `mise` or `tool-versions`, which covers `mise use`, `mise install`,
  and editing a config in the editor. After a config changes by other means
  (for example `git pull`), `cd .` applies it.
- **No `find` or `$(...)` at startup for cheap checks.** The man cache age uses
  a glob qualifier under a local `extended_glob`.

## Remaining costs

- `cd` still pays `mise hook-env` (about 13 ms) and `zoxide add` (about 13 ms)
  in `chpwd`, outside the measured prompt path.
- The turbo plugins load right after the first prompt and block it for roughly
  100 ms while carapace, compinit, and the highlighters initialise; typed keys
  queue and are not lost.
- Per keystroke: fast-syntax-highlighting and the autosuggestion lookup.
- Outside zsh: tmux (`escape-time 0`, `status-interval 0`) and Alacritty, which
  redraws at the display refresh rate. Karabiner adds a hop to every key on macOS.

## Measuring

- `scripts/zsh-latency.sh [dir]` for the end-to-end numbers above; it also
  fails on the p10k console-output warning.
- Per-hook cost inside a running shell: time each entry of `$precmd_functions`
  and `$chpwd_functions` in a loop with `EPOCHREALTIME`.
- Startup breakdown: `PS4=$'+%D{%s%.}|%N:%i> ' zsh -x -l -i -c exit 2>&1` and
  diff consecutive timestamps; `zsh -i -c exit` does not run precmd, so turbo
  plugins never load in that measurement.
