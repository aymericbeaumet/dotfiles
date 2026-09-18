# Neovim navigation

The leader key is Space. The jump sequence is:

`Space` → `s` → search character → first hint character → second hint character

The search character is literal, including punctuation and Unicode. Matching follows Neovim's
`ignorecase` and `smartcase` settings. Each visible target receives a two-character hint: the
first key selects its group, and the second jumps to the target. Both hint keys are required
even for a single match. The mapping works in normal, visual, and operator-pending modes.

Escape, Enter, and Backspace cancel. Unrecognized hint keys leave the selection active without
moving the cursor. Hints use the Colemak alphabet `tnseridhaoplfuwygjq`, allowing 361 unique
pairs; any additional matches remain unlabeled.

The existing Lua plugin [flash.nvim](https://github.com/folke/flash.nvim#-examples) provides the
matching and hint display. The mapping lives in
[`lua/plugins/init.lua`](../.config/nvim/lua/plugins/init.lua), and its two-stage behavior lives
in [`lua/config/jump.lua`](../.config/nvim/lua/config/jump.lua). Keep the search fixed to its
first character and disable automatic jumps so both hint keys remain part of the sequence.

## Worktrees and agents

Manage worktrees with Bonsai from the shell, then open Neovim in the chosen worktree.
`Space cc` opens or focuses the Claude terminal; `Space ca` sends a visual selection to it.
Completion combines LSP results, paths, snippets, and buffer words.

## Language tools

[`lua/config/languages.lua`](../.config/nvim/lua/config/languages.lua) owns language tooling.
Its explicit Mason package map works before plugins load, deduplicates shared binaries, and
marks toolchain-owned tools such as `rustfmt` with `false`. Register every new linter or
formatter there. Mason appends its binary directory to `PATH`, preserving project and mise
tool precedence.

Linting runs after saving a normal file or with `:Lint`; it skips buffers marked by the
existing 200 KiB large-file guard. Run the focused checks without loading installed plugins:

```sh
rtk proxy nvim --headless -u NONE -n -i NONE -l scripts/check-neovim.lua
```
