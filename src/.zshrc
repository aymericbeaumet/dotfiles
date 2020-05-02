# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

fpath=($HOME/.zsh/bundle/zsh-completions/src $fpath)
autoload -Uz compinit && compinit

...() {
  local path="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$path"
}

cd() {
  builtin cd "$@" >/dev/null
}

d() {
  local path="$(fd --type directory                         | fzf -1 -0 -q "$1")"
  if [ -z "$path" ]; then
    echo 'wow such empty' 1>&2
    return
  fi
  cd "$path"
}

D() {
  local path="$(fd --type directory --hidden --exclude .git | fzf -1 -0 -q "$1")"
  if [ -z "$path" ]; then
    echo 'wow such empty' 1>&2
    return
  fi
  cd "$path"
}

f() {
  local path="$(fd --type file                         | fzf -1 -0 -q "$1")"
  if [ -z "$path" ]; then
    echo 'wow such empty' 1>&2
    return
  fi
  "$EDITOR" "$path"
}

F() {
  local path="$(fd --type file --hidden --exclude .git | fzf -1 -0 -q "$1")"
  if [ -z "$path" ]; then
    echo 'wow such empty' 1>&2
    return
  fi
  "$EDITOR" "$path"
}

g() {
  if (( $# == 0 )); then
    command hub status -sb
  else
    command hub "$@"
  fi
}
compdef g=git

alias j=jobs

k() {
  if (( $# == 0 )); then
    local context=$(kubectx -c)
    local namespace=$(kubens -c)
    echo "$context/$namespace"
  else
    command kubectl "$@"
  fi
}
compdef k=kubectl

alias ls='ls --color=auto -pFH --group-directories-first'
alias ll='ls -hl'
alias l=ll
alias la='ll -A'

alias mkdir='mkdir -p'

alias v=nvim
alias vi=nvim
alias vim=nvim

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

alias tree='tree -a -I .git --dirsfirst'

alias w='watchexec --clear --restart -i ".*" -i "*.md" -i Dockerfile --'

unalias z &> /dev/null
z() {
  [ $# -gt 0 ] && _z "$*" && return
  cd "$(_z -l 2>&1 | fzf --nth 2.. +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

urls() {
  fc -rl 1 | squeeze --url | sort -u
}

furls() {
  urls | fzf | pbcopy
}

# global env
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less
export GREP_OPTIONS='--color=auto'

# bindings
bindkey -e
bindkey '^[[Z' reverse-menu-complete # allow shift-TAB to backward complete
autoload -U select-word-style && select-word-style bash

# changing directories (http://zsh.sourceforge.net/Doc/Release/Options.html#Changing-Directories)
setopt AUTO_CD
setopt AUTO_PUSHD
setopt CHASE_DOTS
setopt CHASE_LINKS
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_TO_HOME

# completion (http://zsh.sourceforge.net/Doc/Release/Options.html#Completion-2)
setopt ALWAYS_TO_END
setopt AUTO_LIST
setopt AUTO_MENU
setopt AUTO_PARAM_KEYS
setopt AUTO_PARAM_SLASH
setopt AUTO_REMOVE_SLASH
setopt LIST_AMBIGUOUS
setopt LIST_PACKED
setopt LIST_TYPES
setopt +o nomatch
unsetopt COMPLETE_IN_WORD
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

# expansion and globbing (http://zsh.sourceforge.net/Doc/Release/Options.html#Expansion-and-Globbing)
setopt BAD_PATTERN
setopt GLOB

# history (http://zsh.sourceforge.net/Doc/Release/Options.html#History)
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_NO_FUNCTIONS
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_BY_COPY
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
unsetopt APPEND_HISTORY
unsetopt INC_APPEND_HISTORY

# input/output (http://zsh.sourceforge.net/Doc/Release/Options.html#Input_002fOutput)
setopt INTERACTIVE_COMMENTS
setopt RC_QUOTES
unsetopt FLOW_CONTROL
stty stop undef
stty start undef

# prompting (http://zsh.sourceforge.net/Doc/Release/Options.html#Prompting)
precmd() { # set title + restore cursor
  print -n "\ek$(pwd)\e\\"
  echo -ne '\e[5 q'
}
source ~/.zsh/bundle/powerlevel10k/powerlevel10k.zsh-theme
source ~/.p10k.zsh
source ~/.zsh/bundle/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/bundle/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf
source /usr/local/opt/fzf/shell/key-bindings.zsh
export FZF_DEFAULT_OPTS='--ansi --border --inline-info --height 40% --layout=reverse'

# secrets
source "$HOME/.secrets/.zshrc"

# start or join a default tmux session
if [ -z "$TMUX" ]; then;
  t scratch
fi
