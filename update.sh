#!/bin/sh

# Update repo
git pull origin master

# Update submodules
git submodule foreach git pull origin master

exit 0
