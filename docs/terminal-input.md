# Stray mouse characters at the shell prompt

A terminal program can leave mouse tracking enabled after it exits. With legacy
mouse encoding, pointer movement then inserts short runs of letters and punctuation
at the zsh prompt. Taking a macOS region screenshot can expose this as the pointer
moves over the terminal; the screenshot shortcut alone does not identify the cause.

Inspect the pane's state with:

```sh
rtk proxy tmux list-panes -a -F '#{pane_id} #{pane_current_command} mouse=#{mouse_any_flag} sgr=#{mouse_sgr_flag}'
```

An idle zsh prompt should have `mouse=0`. `mouse=1 sgr=0` means tmux forwards
legacy mouse reports to the shell. `.zshrc` clears tracking and extended mouse
encoding in its existing `precmd` cursor-reset hook. Programs can enable their own
mouse modes while running; tmux's mouse support stays enabled.

For a shell that has not loaded the updated configuration, clear the current
input with Ctrl+U and run:

```sh
rtk proxy printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l'
```

New shells load the prevention automatically. Existing shells can load it with
`source ~/.zshrc`. Do not infer which application leaked the mode from the flags
alone; that requires observing the transition when the application exits.

## Thumbs installation

`prefix y` runs `scripts/tmux-thumbs.sh`. Mise downloads the pinned release's
`thumbs` and `tmux-thumbs` binaries during setup or on first use, without the TPM
plugin's interactive installer. The launcher preserves the `@thumbs-*` settings
and links the hint binary into the directory layout the upstream driver expects.
The release has an Intel macOS binary, so Apple Silicon uses Rosetta; Linux uses
its native release. The macOS asset override is scoped to that platform in mise.
