#!/bin/sh

# Update repo && update submodules
git pull origin master && git submodule foreach git pull origin master

exit $?
