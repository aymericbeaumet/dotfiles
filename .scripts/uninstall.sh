#!/bin/bash

# Fix path
cd "$(dirname $0)/.."

# Source configuration
source .scripts/config

files=(`find $INSTALL_DIR -maxdepth 1 -name '.*' -type l | sort`)

dotfiles_path=`pwd`

for i in ${files[@]} ; do
  if [[ `readlink $i` =~ $dotfiles_path ]] && [ -e $i ]; then
    # If a backup file exists, restore it
    if [ -f $i.$BACKUP_EXT ] ; then
      mv -vf $i.$BACKUP_EXT $i &>/dev/null && \
      echo "Restoring \"$i.$BACKUP_EXT\""
    # Else just remove
    else
      rm -vf $i &>/dev/null && \
      echo "Removing \"$i\""
    fi
  fi
done

exit 0
