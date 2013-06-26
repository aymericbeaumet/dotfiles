#!/bin/bash

# Fix path
cd "$(dirname $0)/.."

# Source configuration
source .scripts/config

files=("$(find "$INSTALL_DIR" -maxdepth 1 -name '.*' ! -name ".*.$BACKUP_EXT" -type l | sort)")

dotfiles_path="$(pwd)"

for file in ${files[@]} ; do
  if [[ "$(readlink "$file")" =~ "$dotfiles_path" ]] && [ -e "$file" ]; then
    # If a backup file exists, restore it
    if [ -e "$file.$BACKUP_EXT" ] ; then
      rm -rf "$file" &>/dev/null
      mv -vf "$file.$BACKUP_EXT"  "$file" &>/dev/null && \
      echo "Restoring \"$file.$BACKUP_EXT\" over \"$file\""
    # Else just remove it
    else
      rm -vf $file &>/dev/null && \
      echo "Removing \"$file\""
    fi
  fi
done

exit 0
