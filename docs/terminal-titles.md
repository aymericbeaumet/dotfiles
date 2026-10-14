# Terminal titles and pane context

One channel carries pane context: the terminal title (OSC 2). Every program
already has it, so nothing in these dotfiles polls processes, tracks agent
state in tmux options, or runs hooks to rebuild what the program reports.

## Who reports what

- **zsh** sets the title to the current directory at each prompt and to the
  running command (first line, 80 characters) while it runs, in every shell.
  Over ssh it prefixes the host (`host:~/path`) so remote panes stay
  recognisable; a program running remotely then takes the title over the same
  way it would locally.
- **Claude Code** sets a generated session summary with a glyph for its state
  (`✳` idle, a spinner while working). `CLAUDE_CODE_DISABLE_TERMINAL_TITLE`
  would turn it off; keep it unset. It also probes OSC 7501, which tmux's
  `allow-passthrough on` lets through.
- **Codex** sets a spinner plus the session title and repository
  (`⠸ Verify lead firing | repo`).
- **Grok** sets the title from its `title.enabled` option, on by default.
- **Other TUIs** (Neovim, lazygit, newsboat) keep whatever they set; the next
  zsh prompt restores the directory.

## Where it shows

`pane-border-format` in `.tmux.conf` prints `#{pane_title}`, with `[ZOOMED]`
in front of a zoomed window. tmux initialises a pane title to the hostname, so
a pane still carrying that value has not reported yet and shows its current
command instead. Windows keep `automatic-rename-format` (the directory
basename) for the status line. The Alacritty window uses a fixed title with
`dynamic_title = false` because the window has no decorations; tmux's
`set-titles` stays off for the same reason.

## Rules

- Do not add client hooks, tmux user options (`@agent-*`), or
  `pane_current_command` matching to label panes. If a program's title is
  missing or wrong, fix it at the program (its title setting) or report it
  from the program's own hook with a plain OSC 2 write to `/dev/tty`.
- zsh title hooks write through `_tty_print` like `_reset_cursor`, because p10k's
  instant prompt captures stdout until its own precmd (`docs/zsh-performance.md`).
- `scripts/check.sh` fails on `@agent-kind`, `@agent-idle`, the retired
  `agent-pane-*` scripts, and a border format that does not read `pane_title`.
