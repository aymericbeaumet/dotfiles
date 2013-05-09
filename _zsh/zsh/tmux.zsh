##############
# Tmux stuff #
##############

if cmd_exists tmux ; then

  if [ -n "$TMUX" ] ; then
    export TERM='screen-256color'
  elif [ -r '/usr/share/terminfo/78/xterm-256color' ] || \
       [ -r '/lib/terminfo/x/xterm-256color' ]        || \
       locate 'xterm-256color' &>/dev/null ; then
    export TERM='xterm-256color'
  else
    export TERM='xterm'
  fi

  alias tmux="tmux attach || tmux new"

fi
