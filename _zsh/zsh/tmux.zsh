# Tmux
###

if cmd_exists tmux ; then

  if [ -n "$TMUX" ] ; then
    export TERM=screen-256color
  else
    export TERM=xterm-256color
  fi

  # one session at once
  alias tmux="tmux attach || tmux new"

fi
