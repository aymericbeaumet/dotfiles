#!/bin/bash

set -e

# cd to the project root directory
cd "$(dirname "$0")/.."

# Update repo
git pull origin master

# Update submodules (init them if needed)
git submodule update --init --recursive

for build_script in "$(find . -mindepth 2 -maxdepth 2 -name '.build.sh')" ; do
  if [ -r "$build_script" ] ; then
    echo '    <<<'
    sh "$build_script"
    echo '    >>>'
  fi
done

exit 0
