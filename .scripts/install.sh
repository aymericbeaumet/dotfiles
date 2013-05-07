#!/bin/bash

# Fix path
cd "$(dirname "$0")/.."

##
#config
##
. "$(cd "$(dirname "$0")"; pwd)/config.cfg"

current_path="$(pwd)"
current_user="$(whoami)"

if [ -z "$current_path" ] || [ -z "$current_user" ] ; then
  echo 'Error: need the current path and the current user.'
  exit 1
fi

# get the configuration file to install (directories prefixed by an '_')
files2install=($(find . -mindepth 1 -maxdepth 1 -name '_*' -exec echo {} \; | sort | sed 's#./_\(.*\)#\1#g'))

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


echo 'This script will install the configuration files for the following programs:'
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


echo '---'
echo 'Checking dependencies...'
git submodule update --init


# Installing configuration files
echo '---'
for i in "${files2install[@]}" ; do
  if ! cmd_exists "$i" ; then
    echo "Skipping $i stuff..."
    continue
  fi

  echo "Installing $i stuff..."

  for j in $(ls "_$i/") ; do
    # if a custom installation script is present, skip it
    if [ "$j" = 'install.sh' ] ; then
      continue
    fi

    file_from="$current_path/_$i/$j"
    file_toward="$INSTALL_DIR/.$j"
    do_backup "$file_toward" &&
      ln -sf "$file_from" "$file_toward" &>/dev/null &&
      echo "    \"$file_from\" -> \"$file_toward\""
  done

  custom_install_script="$current_path/_$i/install.sh"
  if [ -f "$custom_install_script" ] ; then
    echo "    Loading custom installation script \"$custom_install_script\""
    . "$custom_install_script"
  fi

  echo '---'
done

echo 'Done!'

exit 0
