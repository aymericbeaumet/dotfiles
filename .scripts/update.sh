#!/bin/sh

# Fix path
cd "$(dirname "$0")/.."

# Update repo and init/update submodules
git pull origin master && \
  git submodule update --init

exit $?
