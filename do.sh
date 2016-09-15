#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"

WHOAMI="$(whoami)"

# Configure the OS
# $ ./setup.sh configure
function __configure {
  case "$(uname -s)" in
    Darwin)
      # Fix zsh compinit
      zsh -c 'compaudit | xargs chmod g-w'
      # Fix /usr/local permissions
      sudo chown -R "$WHOAMI:admin" /usr/local
      # Change default shell
      sudo chsh -s "$(which zsh)" "$WHOAMI"
      # Reduce resize time for windows (http://apple.stackexchange.com/a/142734/106194)
      defaults write NSGlobalDomain NSWindowResizeTime .001
      # Disable swipe (http://apple.stackexchange.com/a/80163/106194)
      defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool FALSE
      # Better looking fonts by disable OS anti-aliasing (http://stackoverflow.com/a/32067365/1071486)
      defaults write org.vim.MacVim AppleFontSmoothing -int 0
      defaults write uk.foon.Neovim AppleFontSmoothing -int 0
      ;;
  esac
}

# Install/Update the dependencies
# $ ./setup.sh install
function __install {
  git submodule update --init --recursive
  # install brew dependencies
  brew tap homebrew/bundle
  brew bundle check || brew bundle
  # install latest node
  n latest
  # install fzf dependencies
  # [ -x "$(brew --prefix fzf 2>/dev/null)/install" ] && "$(brew --prefix fzf)/install" --all
}

# Create the symlinks in the $HOME directory
# $ ./setup.sh symlink
function __symlink {
  from_directory="$(pwd)/home"
  find "$from_directory" -type file -o -type link | while read from ; do
    to="$HOME/${from##"$from_directory/"}"
    to_directory="$(dirname "$to")"
    rm -rf "$to"
    mkdir -p "$to_directory"
    ln -svf "$from" "$to"
  done
}

for command in "$@" ; do
  if [[ "$(type "__$command" 2>/dev/null)" == *function* ]] ; then
    printf "\e[94m$command...\e[0m\n"
    __$command
    printf "\e[92mok\e[0m\n"
  else
    printf "\e[91m-> skipping unknown command '$command'\e[0m\n" >&2
  fi
done

exit 0
