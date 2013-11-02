#!/bin/bash

# Abort on error
set -e

# cd to the project root directory
cd "$(dirname "$0")/.."

# Update repo
git pull origin master

# Init & Update submodules
git submodule update --init --recursive

# Load custom build script (if present)
for build_script in "$(find . -mindepth 2 -maxdepth 2 -name '.build.sh')" ; do
  if [ -r "$build_script" ] ; then
    echo "    Loading custom built script: \"$build_script\""
    echo '    <<<'
    bash "$build_script"
    echo '    >>>'
  fi
done

exit 0
