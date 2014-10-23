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
  wget
  xz
  zsh
)

cask=(
  alfred
  dash
  firefox
  thunderbird
  iterm2
  transmission
  vlc
)

NODE_STABLE=0.10
NODE_UNSTABLE=0.11
nvm=(
  "$NODE_STABLE"
  "$NODE_UNSTABLE"
)

npm=(
  coffeescript
  grunt
  gulp
  jshint
  karma-cli
  tslint
  typescript
  uglify-js
)

gem=(
  heroku
  travis
)

# Install Brew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install Brew packages
for package in "${brew[@]}" ; do brew install "$package" ; done

# Install Cask apps
for app in "${cask[@]}"     ; do brew cask install "$application" ; done

# Install NVM versions
for version in "${nvm[@]}"  ; do nvm install "$app" ; done
nvm alias default "$NODE_STABLE"
nvm use "$NODE_STABLE"

# Install NPM packages
for package in "${npm[@]}"  ; do npm install -g "$app" ; done

# Install Gem packages
for package in "${gem[@]}"  ; do gem install "$app" ; done

exit 0
