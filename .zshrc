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

fpath=(
  "$HOME/.zsh/bundle/ohmyzsh/plugins/gitfast"
  "$HOME/.zsh/bundle/zsh-completions/src"
  $fpath
)
autoload -Uz compinit && compinit

# fzf-tab plugin (must be loaded after compinit, before zsh-autosuggestions)
source "$HOME/.zsh/bundle/fzf-tab/fzf-tab.plugin.zsh"
# show git branch preview when completing `g co`
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always -n 20 $word'
zstyle ':fzf-tab:complete:g:argument-rest' fzf-preview 'git log --oneline --graph --color=always -n 20 $word 2>/dev/null || git diff --color=always $word 2>/dev/null'
# use tmux popup if available
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
# disable sort when completing options (keep order from completion function)
zstyle ':completion:*:git-checkout:*' sort false

...() {
  dirpath=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  cd "$dirpath" || exit 1
}

g() {
  if (( $# == 0 )); then
    command git st
  else
    command git "$@"
  fi
}
compdef g=git

z() {
  local dirpath
  if (( $# == 0 )); then
    dirpath="$(zoxide query --list | fzf)"
  else
    dirpath="$(zoxide query --list | fzf --filter="$*" | head -1)"
  fi
  if [ -n "$dirpath" ]; then
    cd "$dirpath" || exit 1
  fi
}

# global env
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export EDITOR=nvim
export PAGER=less
export XDG_CONFIG_HOME="$HOME/.config"

# aliases
alias ap=ansible-playbook
alias b=bat
alias ls='eza --group --group-directories-first --sort=Name'
alias l='ls -l'
alias la='l -a'
alias tree='l -R --tree'
alias t='tree'
alias ta='la -R --tree'
alias tf=terraform
alias v=$EDITOR
alias vi=$EDITOR
alias vim=$EDITOR
alias w='watchexec --restart --clear --'

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

# trigger command line edition with $EDITOR on ^X^E
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey "^X^E" edit-command-line

# fzf plugin
source "$(brew --prefix fzf)/shell/completion.zsh" 2>/dev/null
source "$(brew --prefix fzf)/shell/key-bindings.zsh"
export FZF_DEFAULT_OPTS="\
  --ansi \
  --bind ctrl-y:preview-up,ctrl-e:preview-down,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down \
  --border \
  --height=40% \
  --inline-info \
  --layout=reverse
"
export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude '.git'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type=d --strip-cwd-prefix"

# fzf-git plugin
source "$HOME/.zsh/bundle/fzf-git/fzf-git.sh"

# zoxide plugin
eval "$(zoxide init zsh --hook=prompt --no-cmd)"

# zsh-autosuggestions plugin
source "$HOME/.zsh/bundle/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zsh-syntax-highlighting plugin
source "$HOME/.zsh/bundle/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/aymericbeaumet/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
