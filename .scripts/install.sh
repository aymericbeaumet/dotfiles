#!/bin/bash

# Abort on error
set -e

# Fix path
cd "$(dirname "$0")/.."

# Source configuration
source '.scripts/config'

# Get useful informations
current_path="$(pwd)"
current_user="$(whoami)"

# Get the configuration files to install (all the directories except ones prefixed by an '_')
files2install=("$(find . -maxdepth 1 ! -name '.*' ! -name '_*' -type d | sed 's#\./\(.*\)#\1#' | sort)")

# return 0 if $1 exists (as an alias or executable file in $PATH)
cmd_exists()
{
  return $([ $# -ne 0 ] && which $1 &>/dev/null);
}

do_backup()
{
  if [ -z "$1" ] ; then
    return 1
  fi
  if [ -f "$1" ] || [ -d "$1" ] ; then
    rm -rf "$1.$BACKUP_EXT" &>/dev/null
    mv -f "$1" "$1.$BACKUP_EXT" &>/dev/null
  fi
  return 0
}

# warning
echo "This script will install the following configuration files:"
for i in ${files2install[@]} ; do echo "- $i" ; done
echo '(a backup will automatically be done of your current files)'
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


# Installing configuration files
for i in ${files2install[@]} ; do
  if ! cmd_exists "$i" ; then
    echo "Skipping $i stuff... (not found on the system)"
    continue
  fi

  echo "Installing $i stuff..."

  for j in $(ls "$i/" | sort) ; do
    # if the file extension is '.md' or '.mkd'
    # or if hidden files
    # just skip it
    if [[ "$j" =~ ^.+.mk*d$ ]] || [[ "$j" =~ ^\. ]] ; then
      continue
    fi

    file_from="$current_path/$i/$j"
    file_toward="$INSTALL_DIR/.$j"
    do_backup "$file_toward" &&
      ln -sf "$file_from" "$file_toward" &>/dev/null &&
      echo "    \"$file_from\" -> \"$file_toward\""
  done

  install_script="$current_path/$i/.install.sh";
  if [ -r "$install_script" ] ; then
    echo "    Loading custom installation script: \"$install_script\""
    echo '    <<<'
    bash "$install_script"
    echo '    >>>'
  fi
done

exit 0
