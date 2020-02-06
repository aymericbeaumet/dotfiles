# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

alias d=date

g() {
  if (( $# == 0 )); then
    command hub status -sb
  else
    command hub "$@"
  fi
}

...() {
  local p="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$p"
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
alias l=ls
alias ll='ls -hl'
alias la='ll -A'

alias m=man

alias mkdir='mkdir -p'

alias -s {json,yml,yaml,toml}=nvim
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

source /usr/local/opt/fzf/shell/key-bindings.zsh
export FZF_DEFAULT_OPTS='--ansi --border --color=bw --inline-info --height 40% --layout=reverse'

# cd by typing path directly + keep a stack of path (without duplicates)
setopt autocd autopushd pushdignoredups

# disable flow control (give me ^S/^Q back!)
stty stop undef
stty start undef

# bash-like word selection
autoload -U select-word-style && select-word-style bash

# emacs bindings
bindkey -e

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
