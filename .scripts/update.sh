#!/bin/bash

# Fix path
cd "$(dirname "$0")/.."

# Update repo and init/update submodules
git pull origin master || exit $?
git submodule update --init || exit $?

exit 0
