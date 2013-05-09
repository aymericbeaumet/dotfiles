#!/bin/bash

# Config
INSTALL_DIR=~
BACKUP_EXT='bkp'

# Fix path
cd "$(dirname "$0")/.."

# Get useful informations
current_path="$(pwd)"
current_user="$(whoami)"

if [ -z "$current_path" ] || [ -z "$current_user" ] ; then
  echo 'Error: the current path and the current user are mandatory. Aborting...'
  exit 1
fi

# Get the configuration files to install (directories prefixed by an '_')
files2install=($(find . -mindepth 1 -maxdepth 1 -name '_*' -exec echo {} \; \
  | sort | sed 's#./_\(.*\)#\1#g'))

cmd_exists()
{
  if [ "$#" -eq '0' ] || ! which "$1" &>/dev/null ; then
    return 1
  fi
  return 0
}

do_backup()
{
  if [ -z "$1" ] ; then
    return 1
  fi
  if [ -f "$1" ] || [ -d "$1" ] ; then
    rm -rf "$1.$BACKUP_EXT" &>/dev/null || return $?
    mv -f "$1" "$1.$BACKUP_EXT" &>/dev/null || return $?
  fi
  return 0
}


# warning
echo 'This script install the configuration files for the following programs.'
echo 'A backup will automatically be done of your current files.'
for i in "${files2install[@]}" ; do echo "- $i" ; done
echo -n 'Do you wish to continue [Y/n]? '
answer=''
while [ "$answer" != 'y' ] && [ "$answer" != 'yes' ] ; do
  read answer
  answer="$(echo $answer | tr '[:upper:]' '[:lower:]')"
  # default
  if [ -z "$answer" ] ; then
    break;
  fi
  if [ "$answer" = 'n' ] || [ "$answer" = 'no' ] ; then
    exit 0
  fi
done


echo 'Checking dependencies...'
git submodule init


# Installing configuration files
for i in "${files2install[@]}" ; do
  if ! cmd_exists "$i" ; then
    echo "Skipping $i stuff... (not found on the system)"
    continue
  fi

  echo "Installing $i stuff..."

  for j in $(ls "_$i/" | sort) ; do
    file_from="$current_path/_$i/$j"
    file_toward="$INSTALL_DIR/.$j"
    do_backup "$file_toward" &&
      ln -sf "$file_from" "$file_toward" &>/dev/null &&
      echo "    \"$file_from\" -> \"$file_toward\""
  done

  # Each file starting with a dot in the directory will be sourced
  for script in $(find "$current_path/_$i" -mindepth 1 -maxdepth 1 -name '.*' \
    | sort) ; do
    echo "    Loading custom installation script: \"$script\""
    echo '    <<<'
    . "$script"
    echo '    >>>'
  done
done

echo 'dotfiles successfully installed!'

exit 0
