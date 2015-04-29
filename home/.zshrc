autoload -Uz add-zsh-hook
autoload -Uz colors && colors
autoload -Uz compinit && compinit
autoload -Uz select-word-style
autoload -Uz vcs_info

##################
# Initialization #
##################

[ -d ~/.zsh/tmp ] || mkdir ~/.zsh/tmp

###########
# Helpers #
###########

# Check if the OS is Linux
# @return 0 if the OS is Linux
is_linux() { return $([ `uname -s` = Linux ]); }

# Check if the OS is Mac OS X
# @return 0 if the OS is Mac OS X
is_macosx() { return $([ `uname -s` = Darwin ]); }

# Check if the OS is *BSD
# @return 0 if the OS is a BSD
is_bsd() { return $([[ `uname -s` =~ .*bsd.* ]]); }

# Set the tab name
# @param string $1 The desired tab name
set_tab_name() { printf "\e]1;$1\a" }

# Set the window name
# @param string $1 The desired window name
set_window_name() { printf "\e]2;$1\a" }

###########
# Options #
###########

# Directory
setopt AUTO_CD           # change directory without cd (`..` goes up by one)
setopt AUTO_PUSHD        # cd to pushd stack (useful for `cd -<tab>`)
setopt PUSHD_IGNORE_DUPS # do not push dups to cd history

# No beep
unsetopt BEEP      # no beep
unsetopt HIST_BEEP # no beep
unsetopt LIST_BEEP # no beep

# Correction
setopt CORRECT       # auto correct command
unsetopt CORRECT_ALL # do not auto correct the whole command line

# Job Control
setopt CHECK_JOBS # warn about background jobs before shell exit

# Expansion and Globbing
setopt RC_EXPAND_PARAM # expand foo${xx}bar to 'fooabar foobbar foocbar' if xx=(a b c)
setopt EXTENDED_GLOB   # advanced globbing
setopt ALIASES         # expand aliases

# Warning
unsetopt RM_STAR_WAIT # don't wait after `rm *`

# Set Emacs-like bindings
bindkey -e

# Fix delete key
bindkey '^[[3~'  delete-char
bindkey '^[3;5~' delete-char

# Allow backward tab
bindkey '^[[Z' reverse-menu-complete

# Make ^W behave as in bash (delete until slash, not space)
select-word-style bash

###############
# Environment #
###############

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"

export TERM=xterm-256color
if [ -n "$TMUX" ] ; then
  export TERM=screen-256color
fi

export EDITOR=`which vim`
export USE_EDITOR="$EDITOR"
export VISUAL="$EDITOR"
export VIEWER=open
export PAGER=less

#########
# Alias #
#########

# Colorful aliases
alias grep='grep --color=auto'
alias less='less -R'
alias tree='tree -C'

# Define the `updatedb` command on OSX
if is_macosx ; then
  alias updatedb='/usr/libexec/locate.updatedb'
fi

# Pipe standard output to common commands
alias -g G=' | grep'
alias -g L=' | less'

###########
# History #
###########

export SAVEHIST=10000
export HISTSIZE=10000
export HISTFILE="$HOME/.zsh/tmp/history"

setopt APPEND_HISTORY     # do not overwrite history
setopt INC_APPEND_HISTORY # write after each command
setopt SHARE_HISTORY      # share history between multiple shell sessions
setopt EXTENDED_HISTORY   # more information in history (begin time, elapsed time, command)
setopt HIST_IGNORE_DUPS   # avoid duplicate command lines in history
setopt HIST_REDUCE_BLANKS # remove superfluous blanks from history
setopt HIST_IGNORE_SPACE  # do not store a command in history if it begins with a space
setopt HIST_NO_STORE      # do not store the `history` command
setopt HIST_FIND_NO_DUPS  # do not display dups when searching using ^R
setopt HIST_NO_FUNCTIONS  # remove function definition from history

################
# Autocomplete #
################

# Allow arrow navigation
zstyle ':completion:*' menu select

# Don't complete stuff already on the line
zstyle ':completion:*' ignore-line true

# Don't complete directory we are already in
zstyle ':completion:*' ignore-parents parent pwd

# Use a cache to increase speed
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/tmp/cache"

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

# Don't prompt for a huge list, menu it!
zstyle ':completion:*:default' menu 'select=0'

# Separate man page sections
zstyle ':completion:*:manuals' separate-sections true

# Ignore compiled files on vim completion
zstyle ':completion:*:*:(v|vi|vim|mvim):*:*files' ignored-patterns '*.(a|dylib|so|o)'

setopt AUTO_REMOVE_SLASH  # autoremove slash when not needed
setopt AUTO_PARAM_SLASH   # automatically append a slash after a directory
unsetopt COMPLETE_IN_WORD # complete at the end of a word even if the cursor is not after the last character

#######
# Tab #
#######

precmd_set_tab_title()
{
  set_tab_name "$(basename $(pwd))"
}
add-zsh-hook precmd precmd_set_tab_title

##########
# Prompt #
##########

setopt PROMPT_SUBST # allow substitutions in the prompts
setopt TRANSIENT_RPROMPT # remove the right prompt after accepting a command line

zstyle ':vcs_info:*' enable git hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' formats "%r (%{$fg[cyan]%}%s%{$reset_color%}:%{$fg[yellow]%}%b%{$reset_color%}%m|%c%u%a) %{$fg_bold[blue]%}%S%{$reset_color%}"
zstyle ':vcs_info:*' stagedstr "%{$fg[green]%}±%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr "%{$fg[red]%}≠%{$reset_color%}"
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-aheadbehind git-remotebranch

# From: https://github.com/sunaku/home/blob/master/.zsh/config/prompt.zsh#L26
+vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && git status --porcelain | fgrep '??' &> /dev/null ; then
        hook_com[unstaged]+='…'
    fi
}

# From: https://github.com/sunaku/home/blob/master/.zsh/config/prompt.zsh#L39
+vi-git-aheadbehind() {
    local ahead behind
    local -a gitstatus

    behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | tr -d ' ')
    (( $behind )) && gitstatus+=( "↓${behind}" )

    ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    (( $ahead )) && gitstatus+=( "↑${ahead}" )

    hook_com[misc]+=${(j::)gitstatus}
}

# This function will be called each time the prompt has to be generated
precmd_set_prompt()
{
  # get VCS information
  vcs_info

  # left prompt
  if [ -n "$(jobs)" ] ; then
    PROMPT="[%{$fg_bold[green]%}%j%{$reset_color%}&:?%{$fg_bold[green]%}%?%{$reset_color%}] "
  else
    PROMPT="%(0?..[%{$fg_bold[green]%}%j%{$reset_color%}&:?%{$fg_bold[green]%}%?%{$reset_color%}] )"
  fi
  if [ -n "$vcs_info_msg_0_" ] ; then
    PROMPT="$PROMPT${vcs_info_msg_0_/|)/)} " # Replace '|)' by ')' for aestheticism purpose
  else
    PROMPT="$PROMPT%{$fg_bold[blue]%}%30<...<%~%<<%{$reset_color%} "
  fi
  PROMPT="$PROMPT%(!.#.$) "

  # right prompt
  RPROMPT=''
}
add-zsh-hook precmd precmd_set_prompt

# Disable flow control (^S / ^Q)
stty stop undef
stty start undef

##################################
# Specific command configuration #
##################################

###
# Git
###

# `git_wrapper` (without argument) will invoke `git status -sb`
# `git_wrapper ...` will invoke `git ...`
git_wrapper()
{
  if (( $# == 0 )) ; then
    command git status -sb
  else
    command git "$@"
  fi
}

# Bind `g` and `git` to `git_wrapper` (disable globing to avoid problem with
# parameter containing extended globing characters, like '#' or '^')
alias g='noglob git_wrapper'
alias git='noglob git_wrapper'

# Working completion
compdef g=git
compdef git_wrapper=git

###
# du
###

alias du='du -h'

###
# ls
###

local OS_SPECIFIC_LS_OPTIONS=''
if is_macosx || is_bsd ; then
  OS_SPECIFIC_LS_OPTIONS='-G'
elif is_linux ; then
  OS_SPECIFIC_LS_OPTIONS='--color=auto'
fi
alias ls="ls -p -F $OS_SPECIFIC_LS_OPTIONS"
alias ll='ls -hl' ; compdef ll=ls
alias l='ll' ; compdef l=ls
alias la='ll -A' ; compdef la=ls

# nice ls colors (even on Mac OS X)
unset LS_COLORS
unset LSCOLORS
if is_macosx || is_bsd ; then
  export CLICOLOR=1
  export LSCOLORS=ExGxxxdxCxDxDxxxaxExEx
else
  export CLICOLOR=0
fi

###
# Terminal
###

set_window_name "$(whoami)@$(hostname)"

################
# Lazy loading #
################

fpath=(
  "$HOME/.zsh/autoload"
  "$HOME/.zsh/completion"
  "${fpath[@]}"
)

# Boot2docker / Docker
autoload -Uz boot2docker docker

# homeshick
autoload -Uz homeshick

# nvm / Node.js / npm
autoload -Uz nvm node npm

# rbenv / Ruby
autoload -Uz rbenv ruby

# pyenv / Python
autoload -Uz pyenv python

#######################
# Synchronous loading #
#######################

# zsh-syntax-highlighting
source "$HOME/.zsh/bundle/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
