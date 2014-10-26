#!/usr/bin/env bash

brew=(
  ack
  caskroom/cask/brew-cask
  cmake
  git
  hg
  htop
  macvim
  mongodb
  nvm
  pandoc
  redis
  s3cmd
  tmux
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
  grunt
  gulp
  jasmine
  jscs
  jshint
  karma-cli
  mocha
  trash
  tslint
  typescript
  uglify-js
  watchify
)

# Fetch dotfiles
git clone git://github.com/andsens/homeshick.git "$HOME/.homesick/repos/homeshick"
source "$HOME/.homesick/repos/dotfiles/home/.zlogin"
homeshick clone git@github.com:aymericbeaumet/dotfiles
homeshick link dotfiles

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

exit 0
