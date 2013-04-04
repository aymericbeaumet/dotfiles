#!/bin/bash

. "$(cd "$(dirname "$0")"; pwd)/config.cfg"

restore_backup()
{
  if [ -z "$1" ] ; then
    return
  fi
  rm -rf "$1" &>/dev/null
  if [ -f "$1.$BACKUP_EXT" ] || [ -d "$1.$BACKUP_EXT" ] ; then
    mv -f "$1.$BACKUP_EXT" "$1" &>/dev/null
  fi
}

##
#warning
##

echo 'This script will restore your original configuration files for:'
find . -name '_*' -mindepth 1 -maxdepth 1 -exec echo {} \; | sed 's#./_\(.*\)# - \1#g'
echo
echo -n 'Do you wish to continue [y/N]? '
answer=''
while [ "$answer" != 'y' ] && [ "$answer" != 'yes' ] ; do
  read answer
  answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
  # default
  if [ -z "$answer" ] ; then
    exit 0
  fi
  if [ "$answer" = 'n' ] || [ "$answer" = 'no' ] ; then
    exit 0
  fi
done

restore_backup "$GIT_CONF_FILE"
restore_backup "$TMUX_CONF_FILE"
restore_backup "$TMUX_CONF_DIR"
restore_backup "$VIM_CONF_FILE"
restore_backup "$VIM_CONF_DIR"
restore_backup "$ZSH_CONF_FILE"
restore_backup "$ZSH_CONF_DIR"

echo 'Done!'

exit 0
