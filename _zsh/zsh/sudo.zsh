# insert sudo at start of command line using M-S

if cmd_exists sudo ; then
  insert_sudo () { zle beginning-of-line; zle -U "sudo " }
  zle -N insert-sudo insert_sudo
  bindkey "^[s" insert-sudo
fi
