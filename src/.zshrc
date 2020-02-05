# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

alias d=date

source /usr/local/opt/fzf/shell/key-bindings.zsh
export FZF_DEFAULT_OPTS='--ansi --border --color=bw --inline-info --height 40% --layout=reverse'

g() {
  if (( $# == 0 )); then
    command hub status -sb
  else
    command hub "$@"
  fi
}

...() {
  local p="$(git rev-parse --show-toplevel || pwd)"
  echo "$p"
  cd "$p"
}

alias k=kubectl

alias l='ls -pFH --group-directories-first'
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

# disable flow control (give me ^S/^Q back!)
stty stop undef
stty start undef

# bash-like word selection
autoload -U select-word-style && select-word-style bash

# emacs bindings
bindkey -e

# custom prompt (which restores cursor to |)
export PROMPT="$(echo -ne '\e[5 q')$ "

source "$HOME/.secrets/.zshrc"
