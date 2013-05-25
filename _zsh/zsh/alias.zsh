# Alias
###

if cmd_exists rm ; then
  if cmd_exists find ; then
    alias clean='find . -type f -and \( -name ".*.sw[a-z]" -or -name "*~" \) -exec printf "\033[32m[-]\033[00m Delete file \033[31m{}\033[0m\n" \; -exec rm {} \;'
  else
    alias clean='rm -f **/{.*.sw[a-z],*~}'
  fi
fi

if cmd_exists vim ; then
  unalias vim &>/dev/null
  alias vi=vim
  alias v=vim
  compdef vi=vim
  compdef v=vim
fi

# bind some extension to be opened with $EDITOR
alias -s c=$EDITOR
alias -s cpp=$EDITOR
alias -s h=$EDITOR
alias -s hh=$EDITOR
alias -s hpp=$EDITOR
alias -s html=$EDITOR
alias -s css=$EDITOR
alias -s js=$EDITOR

# bind some extension to be opened with $PAGER
alias -s txt=$PAGER

# bind some extension to be opened with $VIEWER
alias -s bmp=$VIEWER
alias -s gif=$VIEWER
alias -s jpg=$VIEWER
alias -s png=$VIEWER

# bind some extension to be opened with $SHELL
alias -s sh=$SHELL

# bind some extension to be directly executed
if cmd_exists php ; then
  alias -s php=`which php 2> /dev/null`
  alias -s php3=`which php 2> /dev/null`
  alias -s php4=`which php 2> /dev/null`
  alias -s php5=`which php 2> /dev/null`
fi
cmd_exists python && alias -s py=`which python 2> /dev/null`
cmd_exists perl && alias -s pl=`which perl 2> /dev/null`
cmd_exists ocaml && alias -s ml=`which ocaml 2> /dev/null`

# classic aliases
cmd_exists grep && alias grep='grep --color=auto'
cmd_exists cp && alias cp='cp -v'
cmd_exists mv && alias mv='mv -v'
cmd_exists rm && alias rm='rm -v'
cmd_exists mkdir && alias mkdir='mkdir -v'
cmd_exists rmdir && is_linux && alias rmdir='rmdir -v'
cmd_exists jobs && (alias j='jobs' ; compdef j=jobs)
if cmd_exists man ; then
  alias m=man
  compdef m=man
fi

cmd_exists grep && alias -g G=' | grep' # e.g.: 'ls | grep -e toto' == 'ls G -e toto'
cmd_exists less && alias -g L=' | less'
cmd_exists head && alias -g H=' | head'
cmd_exists tail && alias -g T=' | tail'
[[ -w /dev/null ]] && alias -g N=' &>/dev/null'
