#!/usr/bin/env bash

brew=(
  ack
  bash
  caskroom/cask/brew-cask
  cmake
  git
  hg
  htop
  j1mr10rd4n/tap/meteor
  'llvm --with-clang --with-asan'
  macvim
  mongodb
  nvm
  pandoc
  redis
  s3cmd
  tags
  tmux
  tree
  wget
  xz
  zsh
)

cask=(
  iterm2
  transmission
  vlc
)

NODE_STABLE=0.10
NODE_UNSTABLE=0.11
node=(
  "$NODE_STABLE"
  "$NODE_UNSTABLE"
)

npm=(
  bower
  browserify
  coffeescript
  grunt-cli
  gulp
  jake
  jasmine
  jscs
  jshint
  karma-cli
  meteor
  mocha
  node-gyp
  node-inspector
  trash
  tsd
  tslint
  typescript
  uglify-js
  watchify
)

# Install Brew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install Brew packages
for i in "${brew[@]}" ; do      brew install "$i" ; done

# Install Cask apps
for i in "${cask[@]}" ; do brew cask install "$i" ; done

# Install Node
for i in "${node[@]}" ; do       nvm install "$i" ; done
nvm alias default "$NODE_STABLE"
nvm use "$NODE_STABLE"

# Install NPM packages
for i in "${npm[@]}"  ; do    npm -g install "$i" ; done

# OSX Configuration
defaults write com.apple.screencapture location ~/Pictures/MacBook\ Pro/Screenshots

exit 0
