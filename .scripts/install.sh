#!/bin/bash

# Abort on error
set -e

# cd to the project root directory
cd "$(dirname "$0")/.."

# Get the configuration files to install (remove the './' part)
files2install=("$(find . -maxdepth 1 ! -name '.*' -type d | sed 's#\./\(.*\)#\1#' | sort)")

# Installing configuration files
for program in ${files2install[@]} ; do
  echo "Installing $program stuff..."

  for configuration_file in $(ls "$program/" | sort) ; do
    # if the file extension is '.md' or '.mkd'
    # if hidden files
    # -> then skip them
    if [[ "$configuration_file" =~ ^(.+\.mk?d|\..+)$ ]] ; then
      continue
    fi

    rm -rf ~/."$configuration_file"
    ln -sf "$(pwd)/$program/$configuration_file" ~/."$configuration_file"
  done

  # Load custom installation script (if present)
  install_script="$(pwd)/$program/.install.sh";
  if [ -r "$install_script" ] ; then
    echo "    Loading custom installation script: \"$install_script\""
    echo '    <<<'
    bash "$install_script"
    echo '    >>>'
  fi
done

exit 0
