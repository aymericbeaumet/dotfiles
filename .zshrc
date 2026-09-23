# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

# powerlevel10k instant prompt (must be near top, before any console output)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Deduplicate completion directories before compinit scans them.
typeset -U fpath

_dotfiles_compinit() {
  zicompinit || return
  zicdreplay
  compdef _dotfiles_git_completion git
  compdef g=git
  local dump=${ZINIT[ZCOMPDUMP_PATH]}
  if [[ -s $dump && ( ! -s $dump.zwc || $dump -nt $dump.zwc ) ]]; then
    zcompile "$dump"
  fi
}

_dotfiles_git_completion() {
  # Native _git mishandles aliases after global options and ignores `git -C`.
  if [[ $words[2] == -* ]] && (( $+functions[_carapace_completer] )); then
    local -a words=(git "${words[@]:1}")
    _carapace_completer "$@"
  else
    _git "$@"
  fi
}

_dotfiles_carapace_init() {
  export CARAPACE_BRIDGES="zsh,fish,bash" CARAPACE_MATCH=1
  source <(CARAPACE_EXCLUDES="git,gitk" carapace _carapace zsh)
  compdef _dotfiles_git_completion git
  compdef _git gitk
  compdef g=git
  compdef _files lnav
}

# zinit plugin manager (auto-install if missing, then source)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
if [[ -d "$ZINIT_HOME" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
  ZINIT[ZCOMPDUMP_PATH]="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
  [[ -d ${ZINIT[ZCOMPDUMP_PATH]:h} ]] || (umask 077; command mkdir -p -- "${ZINIT[ZCOMPDUMP_PATH]:h}")

  # theme: powerlevel10k (load immediately for instant prompt)
  zinit ice depth=1
  zinit light romkatv/powerlevel10k

  # completions: add docker completions to fpath (if directory exists)
  [[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

  # plugins (turbo mode: deferred loading for faster startup)
  # All entries below load after the first prompt is rendered, in order.
  # Tool inits (mise/zoxide/carapace) sit after compinit so their
  # compdefs find a ready completion system.
  # Skip Git's semantic highlighter: it runs Git to validate each typed ref.
  zinit wait lucid for \
    blockf \
      zsh-users/zsh-completions \
    atinit"_dotfiles_compinit" atload'unset "FAST_HIGHLIGHT[chroma-git]"' \
      zdharma-continuum/fast-syntax-highlighting \
    atload"!_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
    has'mise' id-as'mise' atinit'eval "$(mise activate zsh)"' \
      zdharma-continuum/null \
    has'zoxide' id-as'zoxide' atinit'eval "$(zoxide init zsh --hook=prompt --no-cmd)"' \
      zdharma-continuum/null \
    has'carapace' id-as'carapace' atinit'_dotfiles_carapace_init' \
      zdharma-continuum/null \
    has'bonsai' id-as'bonsai' atinit'eval "$(bonsai init zsh)"' \
      zdharma-continuum/null \
    junegunn/fzf-git.sh
fi

# theme: powerlevel10k config (outside zinit block; prefer dotfiles path, else symlinked)
if [[ -f "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
fi

# zstyles
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
zstyle ':completion:*' menu select
zstyle ':completion:*' ignore-line true
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
# Each matcher-list entry reruns the entire completer, including subprocesses.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' complete-options true
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:default' menu 'select=0'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:git-checkout:*' sort false
# Prefer refs before scanning modified files; skip expensive reflog suggestions.
# Files remain available as a fallback and explicitly after `git checkout --`.
# The final '-' prevents automatic fallback from adding the excluded tags back.
zstyle ':completion:*:git-checkout:*' tag-order \
  'tree-ishs' 'commits' 'heads' 'heads-local' 'heads-remote' \
  'remote-branch-names-noprefix' '!recent-*' '-'
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'

# git root: global alias expands anywhere (e.g., `ls ...`, `cat .../file.txt`, `...` to cd)
alias -g ...='$(git rev-parse --show-toplevel 2>/dev/null || pwd)'

# git wrapper: `g` runs `git st`, `g <args>` runs `git <args>`
g() {
    if (( $# )); then
        command git "$@"
    else
        command git st
    fi
}

# Codex hooks are version-controlled here; run them without per-hash trust prompts.
codex() {
    command codex --dangerously-bypass-hook-trust "$@"
}

# zoxide: `z` opens fzf for interactive selection, `z <query>` jumps to best match
z() {
  local dir
  if (( $# )); then
    dir=$(zoxide query -- "$@") && cd "$dir"
  else
    dir=$(zoxide query --list | fzf) && cd "$dir"
  fi
}

killport() {
  kill -9 $(lsof -t -i:$1)
}

# wcat <file> / wbat <file>: watchexec the file and cat/bat, re-rendering on change.
wcat() { command watchexec --clear --restart --no-vcs-ignore -w "$1" -- cat -- "$1"; }
wbat() { command watchexec --clear --restart --no-vcs-ignore -w "$1" -- bat --paging=never -- "$1"; }

# man: `man` opens fzf to search all man pages, `man <page>` opens that page
# cache man -k output async on shell startup (refreshes if older than 1 day)
_MAN_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/man-k-cache"
[[ -s "$_MAN_CACHE" && -z $(find "$_MAN_CACHE" -mtime +1 2>/dev/null) ]] || \
  ( command man -k . > "$_MAN_CACHE" 2>/dev/null & )
man() {
  if (( $# )); then
    command man "$@"
  else
    local page
    page=$({ [[ -s "$_MAN_CACHE" ]] && < "$_MAN_CACHE" || command man -k . 2>/dev/null; } \
      | awk '!seen[$1]++' \
      | fzf \
        --nth=1 \
        --tiebreak=begin,length \
        --preview 'command man $(echo {1} | sed -E "s/\([^)]+\)$//")' \
      | awk '{print $1}' | sed -E 's/\([^)]+\)$//') \
      && command man "$page"
  fi
}
alias m=man

# environment (path deduplication is in .zprofile)
export EDITOR=nvim
export PAGER=less
export REPORTTIME=5                # show timing for commands >5s
export KEYTIMEOUT=1                # reduce key sequence delay
export ZLE_RPROMPT_INDENT=0        # fix right-prompt spacing
# LANG/LC_ALL set in .zprofile
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_PAGER="less -R --mouse --wheel-lines=10"

# aliases: tools
alias ap=ansible-playbook
alias b=bonsai
alias tf=terraform
alias htop=btm
# Frees Ctrl+Y from the tty's delayed-suspend handling; see the script.
alias newsboat=~/.dotfiles/scripts/newsboat.sh
alias v=$EDITOR
alias vi=$EDITOR
alias vim=$EDITOR
alias watchexec='watchexec --restart --clear --'

# aliases: eza (ls replacement)
alias ls='eza --group --group-directories-first --sort=Name'
alias l='ls -l'
alias la='l -a'
# tree emulation
alias t='l --tree'
alias ta='t -a'
alias tree='t'

# keybindings
bindkey -e
bindkey '^[[Z' reverse-menu-complete  # shift-tab: reverse completion
autoload -U select-word-style && select-word-style bash

# options: directories
setopt AUTO_CD AUTO_PUSHD CHASE_DOTS CHASE_LINKS PUSHD_IGNORE_DUPS PUSHD_TO_HOME

# options: completion
setopt ALWAYS_TO_END AUTO_LIST AUTO_MENU AUTO_PARAM_KEYS AUTO_PARAM_SLASH
setopt AUTO_REMOVE_SLASH LIST_AMBIGUOUS LIST_PACKED LIST_TYPES
unsetopt nomatch
unsetopt COMPLETE_IN_WORD

# options: globbing
setopt BAD_PATTERN GLOB GLOBDOTS

# options: history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_NO_FUNCTIONS HIST_NO_STORE
setopt HIST_REDUCE_BLANKS HIST_SAVE_BY_COPY HIST_SAVE_NO_DUPS
# SHARE_HISTORY writes each command immediately and imports commands written by
# other live shells, so every tab sees the machine's current history.
setopt SHARE_HISTORY
unsetopt APPEND_HISTORY INC_APPEND_HISTORY

# options: input/output
setopt INTERACTIVE_COMMENTS RC_QUOTES
unsetopt FLOW_CONTROL

# restore cursor shape before prompt
autoload -Uz add-zsh-hook
_reset_cursor() { echo -ne '\e[5 q'; }
add-zsh-hook precmd _reset_cursor

# Report context to the terminal title via OSC 2. Over ssh the far-side tmux
# captures this as pane_title and shows it as "[ssh] ..." (see
# .tmux.conf pane-border-format). Skipped inside a local tmux ($TMUX set), which
# reads the pane border directly; ssh does not forward $TMUX, so a remote shell
# still reports. precmd shows the cwd, preexec the running command.
if [[ -z "$TMUX" ]]; then
  _title_precmd() { print -Pn '\e]2;%~\a'; }
  _title_preexec() { print -rn -- $'\e]2;'"${1}"$'\a'; }
  add-zsh-hook precmd _title_precmd
  add-zsh-hook preexec _title_preexec
fi

# edit command line in $EDITOR with ^X^E
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line

# fzf: shell integration — completion + key-bindings (CTRL-R history, CTRL-T files, ALT-C cd).
# `fzf --zsh` (fzf >= 0.48) emits the integration regardless of install source. This
# matters because mise's fzf ships only the binary — no shell/ scripts to source.
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
export FZF_DEFAULT_OPTS="
  --ansi --border --height=40% --layout=reverse --info=inline
  --bind tab:accept,ctrl-n:down,ctrl-p:up
  --bind ctrl-y:preview-up,ctrl-e:preview-down,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
"
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type=d --strip-cwd-prefix"

# mise, zoxide, carapace are loaded via zinit turbo at the top of this file
