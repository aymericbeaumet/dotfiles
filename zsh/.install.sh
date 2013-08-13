#!/bin/bash
# This script will be sourced during installation

if which chsh &>/dev/null ; then
  echo -n 'Do you want to set your default shell to zsh [y/N]? '
  answer=''
  while [ "$answer" != 'n' ] && [ "$answer" != 'no' ] ; do
    read answer
    answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
    # default
    if [ -z "$answer" ] ; then
      break
    fi
    if [ "$answer" = 'y' ] || [ "$answer" = 'yes' ] ; then
      [ "$(id -u)" -ne 0 ] && echo "$USER, please type your password to proceed:"
      chsh -s "$(which zsh | head -1)"
      break
    fi
  done
fi
