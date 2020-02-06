# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

# https://gist.github.com/ctechols/ca1035271ad134841284
autoload -Uz compinit
if [ -n "${ZDOTDIR}/.zcompdump(#qN.mh+24)" ]; then
  compinit
else
  compinit -C
fi

d() {
  local path="$(fd --type directory | fzf -1 -0 -q "$1")"
  if [ -z "$path" ]; then
    echo 'wow such empty' 1>&2
    return
  fi
  cd "$path"
}

g() {
  if (( $# == 0 )); then
    command hub status -sb
  else
    command hub "$@"
  fi
}

...() {
  local path="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$path"
}

alias j=jobs

k() {
  if (( $# == 0 )); then
    command kubectl config current-context
  else
    command kubectl "$@"
  fi
}

alias ls='ls -pFH --group-directories-first'
alias ll='ls -hl'
alias l=ll
alias la='ll -A'

alias m=man

alias mkdir='mkdir -p'

alias v=nvim
alias vi=nvim
alias vim=nvim

alias p=pwd

t() {
  local target="$1"

  if [ -z "$target" ]; then
    local output="$(command tmux ls | sort | fzf)"
    if [ -z "$output" ]; then
      return
    fi
    target="$(echo "$output" | cut -d: -f1)"
  else
    command tmux has-session -t "$target" &>/dev/null || \
      command tmux new-session -d -c "$HOME" -s "$target"
  fi

  if [ -n "$TMUX" ]; then
    command tmux switch-client -t "$target"
  else
    command tmux attach-session -t "$target"
  fi
}

if [ -z "$TMUX" ]; then; t scratch; fi

alias tree='tree -a -C --dirsfirst'

alias w=watchexec

unalias z &> /dev/null
z() {
  [ $# -gt 0 ] && _z "$*" && return
  cd "$(_z -l 2>&1 | fzf --nth 2.. +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less
export HISTFILE="$HOME/.zsh/tmp/history"

# disable flow control
stty stop undef
stty start undef

# bash-like word selection
autoload -U select-word-style && select-word-style bash

# bindings
bindkey -e

# directory
setopt AUTO_CD           # change directory without cd (`..` goes up by one)
setopt AUTO_PUSHD        # build a stack of cd history (cd -1, cd -2, etc)
setopt PUSHD_IGNORE_DUPS # ignore dups when building the stack

# history
export HISTFILE="$HOME/.zsh/tmp/history"
export SAVEHIST=10000
export HISTSIZE=10000
setopt APPEND_HISTORY       # do not overwrite history
setopt INC_APPEND_HISTORY   # write after each command
setopt SHARE_HISTORY        # share history between multiple shell sessions
setopt EXTENDED_HISTORY     # more information in history (begin time, elapsed time, command)
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS # avoid duplicate command lines in history
setopt HIST_REDUCE_BLANKS   # remove superfluous blanks from history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS

# autocomplete
setopt GLOB_DOTS          # lets files beginning with a . be matched without explicitly specifying the dot.
setopt AUTO_REMOVE_SLASH  # autoremove slash when not needed
setopt AUTO_PARAM_SLASH   # automatically append a slash after a directory
setopt ALWAYS_TO_END      # move cursor to end if word had one match
unsetopt COMPLETE_IN_WORD # complete at the end of a word even if the cursor is not after the last character
# Allow arrow navigation
zstyle ':completion:*' menu select
# Don't complete stuff already on the line
zstyle ':completion:*' ignore-line true
# Don't complete directory we are already in
zstyle ':completion:*' ignore-parents parent pwd
# More complete output (not always)
zstyle ':completion:*' verbose yes
# Fix group name display
zstyle ':completion:*' group-name ''
# Case insensitive completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Ignore completion functions
zstyle ':completion:*:functions' ignored-patterns '_*'
# Explicitly write the type of what the autocomplete has found / was looking for
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches for: %d'
# Don't prompt for a huge list, page it!
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:default' menu 'select=0'
# Separate man page sections
zstyle ':completion:*:manuals' separate-sections true
# allow shift-TAB to backward complete
bindkey '^[[Z' reverse-menu-complete

# custom prompt
export PROMPT='$ '

# restore cursor + newline before prompt (https://stackoverflow.com/a/59576993/1071486)
precmd() {
  echo -ne '\e[5 q'
  precmd() {
    echo -e '\e[5 q'
  }
}

source "$HOME/.secrets/.zshrc"

source /usr/local/opt/fzf/shell/key-bindings.zsh
export FZF_DEFAULT_OPTS='--ansi --border --color=bw --inline-info --height 40% --layout=reverse'
