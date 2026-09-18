# Zsh completion

`.zshrc` owns completion setup on both macOS and Linux. Zinit installs completion
files before running `compinit`; the initializer then registers `git` and `g`.
Tool integrations load afterward.

Ordinary Git commands use Zsh's native `_git` completer. Exclude `git` and `gitk`
only while generating Carapace's registrations, and bind `g=git` after Carapace
loads so the wrapper uses the same Git service. Do not export `CARAPACE_EXCLUDES`
globally: it also disables direct completion requests for excluded commands.
`_dotfiles_git_completion` delegates leading global options
(such as `git -C <directory> co`) to Carapace: native `_git` ignores `-C` and fails
to expand aliases after global options. Other commands retain Carapace completion.

Use one case-insensitive `matcher-list` entry. Each additional entry reruns the
entire completer when nothing matches, including external commands. Git checkout
tries local branches, remote branches, and other refs before modified files, and
skips reflog-based suggestions. Use `git co -- <path>` to complete files directly.
Ctrl-G Ctrl-B from `fzf-git.sh` remains available for fuzzy branch selection.

Git-specific semantic highlighting is disabled because it runs Git subprocesses
to validate typed refs and command arguments, including during completion. Normal
shell syntax highlighting remains enabled.

Completion caches live under `${XDG_CACHE_HOME:-$HOME/.cache}/zsh/`:

- `zcompdump-$ZSH_VERSION` stores completion registrations; its `.zwc` sibling
  caches the compiled dump. Compilation runs only when the dump is missing its
  compiled copy or has changed. Normal `compinit` checks remain enabled.
- `completions/` holds data for completers that support Zsh's `use-cache` style.
  Native Git ref completion does not use that cache. Branches, tags, and modified
  files are queried live, so another shell's changes appear immediately.

Open a new shell or run `exec zsh` after changing completion setup. Profile real
Tab completion after Zinit's deferred plugins have loaded; `zsh -ic` alone does
not exercise the line editor or finish deferred loading. With `zmodload
zsh/zprof`, complete a command and then run `zprof` to find expensive functions.
Compare both the first completion and subsequent completions, including a prefix
with no matches. Check `git co`, `g co`, remote refs, filenames containing spaces,
and switching repositories when changing providers or caching.

References: [Zsh's completion system](https://zsh.sourceforge.io/Doc/Release/Completion-System.html),
[native Git completion](https://github.com/zsh-users/zsh/blob/master/Completion/Unix/Command/_git),
[Carapace exclusions](https://github.com/carapace-sh/carapace-bin/blob/master/pkg/env/env.go).
