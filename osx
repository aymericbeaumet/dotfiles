#!/usr/bin/env bash

set -e

echo . System

  # http://apple.stackexchange.com/a/142734/106194
  echo . . Reduce resize time for windows
  defaults write NSGlobalDomain NSWindowResizeTime .001

echo . Applications

  echo . . Google Chrome

    # http://apple.stackexchange.com/a/80163/106194
    echo . . . Disable swipe
    defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool FALSE

  echo . . MacVim

    # http://stackoverflow.com/a/32067365/1071486
    echo . . . Better looking fonts
    defaults write org.vim.MacVim AppleFontSmoothing -int 0
