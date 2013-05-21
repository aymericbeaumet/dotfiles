if cmd_exists ls ; then
  SPECIFIC_LS_OPTIONS=''
  if is_linux ; then
    SPECIFIC_LS_OPTIONS=--color=auto
  elif is_bsd || is_macosx ; then
    SPECIFIC_LS_OPTIONS=-G
  else
    unalias ls &>/dev/null
  fi
  alias ls="ls -p -F $SPECIFIC_LS_OPTIONS"
  alias ll='ls -hl'
  alias l='ll'
  alias la='ll -A' # list .* files (but not . and ..)

  # good ls colors (even on OSX)
  unset LS_COLORS
  unset LSCOLORS
  if is_macosx || is_bsd ; then
    export CLICOLOR=1
    export LSCOLORS=ExGxxxdxCxDxDxxxaxExEx
  else
    export CLICOLOR=0
  fi
fi

