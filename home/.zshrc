autoload -U add-zsh-hook
autoload -U compinit

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

# Check if a given command exists (as an alias or in the PATH)
# @param string $1 The command to check
# @return 0 if the command exists
is_command() { return $(which "$1" &>/dev/null); }

# Set the tab name
# @param string $1 The desired tab name
set_tab_name() { printf "\e]1;$1\a" }

# Set the window name
# @param string $1 The desired window name
set_window_name() { printf "\e]2;$1\a" }

##########
# Colors #
##########

COLOR_RESET=$'%{\033[0m%}'

COLOR_BOLD=$'%{\033[1m%}'
COLOR_UNDERLINE=$'%{\033[4m%}'
COLOR_INVERSE=$'%{\033[7m%}'

COLOR_BLUE=$'%{\033[38;05;75m%}'
COLOR_SMOOTH_GREEN=$'%{\033[38;05;76m%}'
COLOR_GREEN=$'%{\033[38;05;34m%}'
COLOR_LIGHT_GREEN=$'%{\033[38;05;40m%}'
COLOR_YELLOW=$'%{\033[38;05;220m%}'
COLOR_RED=$'%{\033[38;05;1m%}'
COLOR_ORANGE=$'%{\033[38;05;202m%}'

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

###############
# Environment #
###############

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

# Quick trash access (https://github.com/sindresorhus/trash)
alias t='trash'

# Define the `updatedb` command on OSX
if is_macosx ; then
  alias updatedb='/usr/libexec/locate.updatedb'
fi

# Pipe standard output to common commands
alias -g C=' | wc -l'
alias -g G=' | grep' # e.g.: 'ls | grep -e foo' <=> 'ls G -e foo'
alias -g L=' | less'
alias -g H=' | head'
alias -g T=' | tail'
alias -g S=' | sort'

# Redirect both standard output and standard error to /dev/null
alias -g N=' &>/dev/null'

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

compinit

# Allow arrow navigation
zstyle ':completion:*' menu select

# Ignore compiled files on vi/vim completion
zstyle ':completion:*:*:(v|vi|vim):*:*files' ignored-patterns '*.(a|dylib|so|o)'

# Don't complete stuff already on the line
zstyle ':completion::*:(v|vi|vim|rm):*' ignore-line true

# Don't complete directory we are already in
zstyle ':completion:*' ignore-parents parent pwd

# Use a cache to increase speed
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/tmp/cache"

# Ignore completion functions
zstyle ':completion:*:functions' ignored-patterns '_*'

# More complete output (not always)
zstyle ':completion:*' verbose yes

# Explicitly write the type of what the autocomplete has found / was looking for
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# Don't prompt for a huge list, page it!
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Don't prompt for a huge list, menu it!
zstyle ':completion:*:default' menu 'select=0'

# Fix group name display
zstyle ':completion:*' group-name ''

# Separate man page sections
zstyle ':completion:*:manuals' separate-sections true

# Case insensitive completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

setopt AUTO_REMOVE_SLASH  # autoremove slash when not needed
setopt AUTO_PARAM_SLASH   # automatically append a slash after a directory
unsetopt COMPLETE_IN_WORD # complete at the end of a word even if the cursor is not after the last character

##########
# Prompt #
##########

setopt TRANSIENT_RPROMPT # remove the right prompt after accepting a command line

# This function will be called each time the prompt has to be generated
precmd_set_prompt()
{
  # get Git information for the current directory
  git_prompt="$(git_super_status)"

  # left prompt
  if [ -n "$(jobs)" ] ; then
    PROMPT="[${COLOR_SMOOTH_GREEN}%j${COLOR_RESET}&:?${COLOR_SMOOTH_GREEN}%?${COLOR_RESET}] "
  else
    PROMPT="%(0?..[${COLOR_SMOOTH_GREEN}%j${COLOR_RESET}&:?${COLOR_SMOOTH_GREEN}%?${COLOR_RESET}] )"
  fi
  PROMPT="$PROMPT$COLOR_BLUE%30<...<%~%<<$COLOR_RESET${git_prompt:+ $git_prompt} "
  PROMPT="$PROMPT%(!.#.$) "

  # right prompt
  RPROMPT=''
  if [ -n "$SHLVL" ] && (( $SHLVL > 1 )) ; then
    RPROMPT="[%n$COLOR_BLUE@$COLOR_RESET%M]"
    RPROMPT="$RPROMPT {^$COLOR_BLUE%L$COLOR_RESET}"
  fi
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
  # used by zsh-git-prompt
  __EXECUTED_GIT_COMMAND=1

  if (( $# == 0 )) ; then
    command git status -sb
  else
    command git "$@"
  fi
}
compdef git_wrapper=git

# Bind `g` and `git` to `git_wrapper` (disable globing to avoid problem with
# parameter containing extended globing characters, like '#' or '^')
alias g='noglob git_wrapper'
alias git='noglob git_wrapper'

###
# ls
###

OS_SPECIFIC_LS_OPTIONS=''
if is_linux ; then
  OS_SPECIFIC_LS_OPTIONS='--color=auto'
elif is_bsd || is_macosx ; then
  OS_SPECIFIC_LS_OPTIONS='-G'
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

####################
# External bundles #
####################

###
# zsh-completion (https://github.com/zsh-users/zsh-completions)
###

# Add completion scripts from a custom directory
fpath=("$HOME/.zsh/completion" $fpath)

###
# zsh-git-prompt (https://github.com/olivierverdier/zsh-git-prompt)
###

local zsh_git_prompt="$HOME/.zsh/bundle/zsh-git-prompt/zshrc.sh"
if [ -r "$zsh_git_prompt" ] ; then
  ZSH_THEME_GIT_PROMPT_CACHE=1
  source "$zsh_git_prompt"

  # Change appearance
  ZSH_THEME_GIT_PROMPT_PREFIX='('
  ZSH_THEME_GIT_PROMPT_SUFFIX=')'
  ZSH_THEME_GIT_PROMPT_SEPARATOR='|'
  ZSH_THEME_GIT_PROMPT_BRANCH="$COLOR_YELLOW"
  ZSH_THEME_GIT_PROMPT_STAGED="$COLOR_GREEN±"
  ZSH_THEME_GIT_PROMPT_CONFLICTS="$COLOR_ORANGE×"
  ZSH_THEME_GIT_PROMPT_CHANGED="$COLOR_RED≠"
  ZSH_THEME_GIT_PROMPT_REMOTE=''
  ZSH_THEME_GIT_PROMPT_UNTRACKED='…'
  ZSH_THEME_GIT_PROMPT_CLEAN="$COLOR_LIGHT_GREEN✓"

  # Update zsh-git-prompt data after the first load to avoid missing prompt
  # informations if zsh is started inside a Git repository
  chpwd_update_git_vars
else
  echo 'The "zsh-git-prompt" bundle is not installed.'
fi

###
# zsh-syntax-highlighting (https://github.com/zsh-users/zsh-syntax-highlighting)
###

local zsh_syntax_highlighting="$HOME/.zsh/bundle/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
if [ -r "$zsh_syntax_highlighting" ] ; then
  source "$zsh_syntax_highlighting"
else
  echo 'The "zsh-syntax-highlighting" bundle is not installed.'
fi

###
# zsh-history-substring-search (https://github.com/zsh-users/zsh-history-substring-search)
###

local zsh_history_substring_search="$HOME/.zsh/bundle/zsh-history-substring-search/zsh-history-substring-search.zsh"
if [ -r "$zsh_history_substring_search" ] ; then
  source "$zsh_history_substring_search"
  bindkey -M emacs '^P' history-substring-search-up
  bindkey -M emacs '^N' history-substring-search-down
else
  echo 'The "zsh-history-substring-search" bundle is not installed.'
fi

# added by travis gem
[ -f /Users/ab/.travis/travis.sh ] && source /Users/ab/.travis/travis.sh
