#!/bin/sh

# Stop execution if not on mac os x
if [ "$(uname -s)" != 'Darwin' ] ; then
  echo 'This script has to be used on Mac OSX'
  exit 1
fi

# Config
PACKAGES_DIR=packages
CONF_FILE='Preferences.sublime-settings'
SYSTEM_PACKAGES_DIR="/Users/$USER/Library/Application Support/Sublime Text 2/Packages"
SYSTEM_CONF_FILE="/Users/$USER/Library/Application Support/Sublime Text 2/Packages/User/$CONF_FILE"

# Install all packages
if ! find "$PACKAGES_DIR" -mindepth 1 -maxdepth 1 -type d -exec ln -vsf "$(pwd)/{}" "$SYSTEM_PACKAGES_DIR/" \; ; then
  exit 2
fi

# Copy user configuration file
ln -vsf "$(pwd)/$CONF_FILE" "$SYSTEM_PACKAGES_DIR/User/$CONF_FILE"

exit 0
