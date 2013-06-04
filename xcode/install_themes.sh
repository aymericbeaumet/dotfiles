#!/bin/sh

# Stop execution if not on mac os x
if [ "$(uname -s)" != 'Darwin' ] ; then
  echo 'This script has to be used on Mac OSX'
  exit 1
fi

# Config
THEMES_DIR=./themes
SYSTEM_THEMES_DIR="/Users/$USER/Library/Developer/Xcode/UserData/FontAndColorThemes"

if [ -z "$USER" ] ; then
  echo "Error: this script needs a valid \$USER variable"
  exit 2
fi

if ! mkdir -p "$SYSTEM_THEMES_DIR" ; then
  exit 3
fi

if ! find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -name '*.dvtcolortheme' -exec ln -vsf "$(pwd)/{}" "$SYSTEM_THEMES_DIR/" \; ; then
  exit 4
fi

exit 0
