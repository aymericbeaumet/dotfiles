#!/bin/sh

if [ "$(uname -s)" = 'Darwin' ] ; then
  OS='MacOS X'
elif [ "$(uname -s)" = 'Linux' ] ; then
  OS="$(uname -o)"
else
  OS='Unkown OS'
fi

echo "[$(whoami)@$(hostname)] [$OS]"

exit 0
