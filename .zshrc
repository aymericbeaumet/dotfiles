# Author: Aymeric Beaumet <hi@aymericbeaumet.com> (https://aymericbeaumet.com)
# Github: @aymericbeaumet/dotfiles

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source "$HOME/.p10k.zsh"
source "$HOME/.zsh/bundle/powerlevel10k/powerlevel10k.zsh-theme"

fpath=("$HOME/.zsh/bundle/zsh-completions/src" $fpath)
autoload -Uz compinit && compinit

g() {
  if (( $# == 0 )); then
    command git status -sb
  else
    command git "$@"
  fi
}
compdef g=git

t() {
  if (( $# == 0 )); then
    if [ -n "$TMUX" ]; then
      echo "session=$TMUX"
    else
      tmux attach -t default || tmux new -s default
    fi
  else
    command tmux "$@"
  fi
}
compdef t=tmux

alias brew='arch -arm64 brew'

alias k='kubectl'
alias kdd='kubectl describe deploy'
alias kdi='kubectl describe ingress'
alias kdj='kubectl describe job'
alias kdn='kubectl describe node'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kga='kubectl get all'
alias kgd='kubectl get deploy'
alias kgi='kubectl get ingress'
alias kgj='kubectl get jobs  --sort-by=.status.startTime'
alias kgn='kubectl get nodes --sort-by=.metadata.creationTimestamp'
alias kgp='kubectl get pods  --sort-by=.status.startTime'
alias kgs='kubectl get services'

alias ls='exa --group-directories-first'
alias l='ls -lg'
alias la='l -a'
alias tree='tree -a'

alias v=nvim
alias vi=nvim
alias vim=nvim

alias w='watchexec --restart --clear --'

# global env
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export EDITOR=nvim
export PAGER=less

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
setopt GLOBDOTS

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

# set title + restore cursor before each command
precmd() {
  echo -ne '\e[5 q'
}

# expand ... to be the git root directory
expand-triple-dot() {
  BUFFER="$(sed "s#\.\.\.#$(git rev-parse --show-toplevel 2>/dev/null || pwd)#g" <<< $BUFFER)"
  zle .accept-line
}
zle -N accept-line expand-triple-dot

# allow command line edition in vim with ^F
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey "^F" edit-command-line

# fzf plugin
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
export FZF_DEFAULT_OPTS='--ansi --border --inline-info --height 40% --layout=reverse'

# zoxide plugin
eval "$(zoxide init zsh)"

# zsh-autosuggestions plugin
source "$HOME/.zsh/bundle/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting plugin
source "$HOME/.zsh/bundle/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"