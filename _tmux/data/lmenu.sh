#!/bin/sh

OS="$(uname -s)"
if [ -z "$OS" ] ; then
  OS='Darwin'
fi

echo "[$(whoami)@$(hostname)] [$(uname -o)]"

exit 0
