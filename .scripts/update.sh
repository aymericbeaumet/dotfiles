#!/bin/sh

# Fix path
cd "$(dirname "$0")/.."

# Update repo && update submodules
git pull origin master && git submodule foreach git pull origin master

exit $?
