if which tmux > /dev/null 2> /dev/null ; then
  alias tmux="(pgrep tmux && tmux attach) || tmux"
  if [[ -z "$TMUX" ]] ; then
    if ! pgrep tmux > /dev/null 2> /dev/null ; then
      tmux
    else
      tmux attach
    fi
  fi
fi
