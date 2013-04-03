#!/bin/sh

#config
PLUGINS_DIR='./plugins'

# stop execution if not on mac os x
if [ "$(uname -s)" != 'Darwin' ] ; then
  echo 'This script has to be used on Mac OSX'
  exit 1
fi

# execute all the plugins
if ! find "$PLUGINS_DIR" -name '*.xcodeproj' -mindepth 2 -maxdepth 2 -exec open {} \; ; then
  exit 3
fi

exit 0
