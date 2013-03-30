#!/bin/sh

source './config.cfg'

function restore_backup()
{
  if [ -z "$1" ] ; then
    return
  fi
  rm -rf "$1"
  if [ -f "$1.$BACKUP_EXT" ] || [ -d "$1.$BACKUP_EXT" ] ; then
    mv -f "$1.$BACKUP_EXT" "$1"
  fi
}

##
#warning
##

echo 'This script will restore your original configuration files for:'
echo '  - git'
echo '  - tmux'
echo '  - vim'
echo '  - zsh'
echo
echo -n 'Do you wish to continue [y/N]? '
answer=''
while [ "$answer" != 'y' ] && [ "$answer" != 'yes' ] ; do
  if [ "$answer" = 'n' ] || [ "$answer" = 'no' ] ; then
    exit 0
  fi
  read answer
  answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
  if [ -z "$answer" ] ; then
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
