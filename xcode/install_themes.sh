#!/bin/sh

#config
THEMES_DIR='./themes'
SYSTEM_THEMES_DIR="/Users/$USER/Library/Developer/Xcode/UserData/FontAndColorThemes"

# stop execution if not on mac os x
if [ "$(uname -s)" != 'Darwin' ] ; then
  echo 'This script has to be used on Mac OSX'
  exit 1
fi

if [ -z "$USER" ] ; then
  echo "Error: this script needs a valid \$USER variable"
  exit 2
fi

if ! mkdir -p "$SYSTEM_THEMES_DIR" ; then
  exit 3
fi

if ! find "$THEMES_DIR" -name '*.dvtcolortheme' -mindepth 1 -maxdepth 1 -exec cp -v {} "$SYSTEM_THEMES_DIR/" \; ; then
  exit 4
fi

exit 0
