#!/bin/bash

# cd to the project root directory
cd "$(dirname "$0")/.."

# Update repo
git pull origin master || exit $?

# Init and/or update submodules
git submodule update --init || exit $?

exit 0
