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

restore_backup "$GIT_CONF_FILE"
restore_backup "$TMUX_CONF_FILE"
restore_backup "$TMUX_CONF_DIR"
restore_backup "$VIM_CONF_FILE"
restore_backup "$VIM_CONF_DIR"
restore_backup "$ZSH_CONF_FILE"
restore_backup "$ZSH_CONF_DIR"

exit 0
