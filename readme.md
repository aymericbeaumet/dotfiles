# dotfiles

Hello there! Here you can find my dotfiles for neovim, zsh, tmux, and many other
CLIs. I'm using those on a daily basis, and I'm putting a lot of effort trying
to keep them [simple](https://www.youtube.com/watch?v=LKtk3HCgTa8).

_While I would not recommend to install this on your machine as it is tailored
to my needs, I think it is a good source of inspiration for your own dotfiles._

## Install

```bash
# Clone dotfiles (read-write or read-only)
git clone --recursive git@github.com:aymericbeaumet/dotfiles.git "$HOME/.dotfiles"
git clone --recursive https://github.com/aymericbeaumet/dotfiles.git "$HOME/.dotfiles"

# Symlink dotfiles
"$HOME/.dotfiles/symlink.sh"

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew bundle
```

## Update

```bash
git -C ~/.dotfiles submodule foreach git pull;
brew bundle --cleanup --file ~/.dotfiles/Brewfile;
nvim --headless '+Lazy! sync' +qa;
```

## System config

```
defaults write com.apple.dock "expose-group-apps" -bool "true" && killall Dock
defaults write com.apple.spaces "spans-displays" -bool "true" && killall SystemUIServer
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
```
