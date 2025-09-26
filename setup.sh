#!/usr/bin/env bash

set -ex
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

################
# System Setup #
################

# install brew if not installed
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# install brew dependencies
brew bundle --cleanup --file ./Brewfile

# install git submodules
git submodule update --init --recursive
git submodule update --remote --merge

# symlink dotfiles

symlink() {
	target="$HOME/$1"
	rm -rf "$target"
	mkdir -p "$(dirname "$target")"
	ln -svf "$PWD/$1" "$target"
}

/usr/bin/find . -mindepth 1 -maxdepth 1 \( -type file -o -type link \) \( -name '.*' -o -name 'Brewfile' \) \! -name '.gitmodules' | while read -r file; do
	symlink "${file#./}"
done

/usr/bin/find . -mindepth 1 -maxdepth 1 -type dir -name '.*' \! -name '.config' \! -name '.git' | while read -r dir; do
	symlink "${dir#./}"
done

/usr/bin/find .config -mindepth 1 -maxdepth 1 -type dir | while read -r dir; do
	symlink "$dir"
done

# install neovim plugins
nvim --headless '+Lazy! sync' +qa

########################
# System Configuration #
########################

# keyboard & input
defaults write -g InitialKeyRepeat -int 15                                     # delay before key repeat starts (lower = faster, default ~25)
defaults write -g KeyRepeat -int 2                                             # speed of key repeat (lower = faster, default ~6)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3                       # full keyboard access (tab through all controls, not just text boxes)

# typing & text substitutions
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false     # disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false  # disable smart quotes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false   # disable smart dashes
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false # disable double-space = period
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false # disable automatic spelling correction

# windows & animations
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false               # disable smooth animations for opening/closing windows
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001                  # speed up window resize animation
defaults write -g QLPanelAnimationDuration -float 0                            # disable quick look panel animation

# mission control & spaces
defaults write com.apple.dock "expose-group-apps" -bool "true"                 # group windows by app in mission control
defaults write com.apple.dock expose-animation-duration -float 0.1             # shorten mission control animation
defaults write com.apple.spaces "spans-displays" -bool "true"                  # use separate spaces across multiple displays

# dock
defaults write com.apple.dock autohide -bool true                              # auto-hide the dock
defaults write com.apple.dock autohide-delay -float 0                          # remove delay when auto-hiding dock
defaults write com.apple.dock autohide-time-modifier -float 0.1                # shorten animation time when showing/hiding dock
defaults write com.apple.dock minimize-to-application -bool true               # minimize windows into app’s icon instead of right side of dock
defaults write com.apple.dock orientation -string "left"                       # move dock to the left of the screen
defaults write com.apple.dock springboard-show-duration -float 0.1             # shorten launchpad show animation
defaults write com.apple.dock springboard-hide-duration -float 0.1             # shorten launchpad hide animation
defaults write com.apple.dock springboard-page-duration -float 0.1             # shorten launchpad page animation

# finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true                # always show file extensions
defaults write com.apple.finder AppleShowAllFiles -bool true                   # show hidden files by default
defaults write com.apple.finder ShowPathbar -bool true                         # show path bar at bottom of finder windows
defaults write com.apple.finder ShowStatusBar -bool true                       # show status bar (file counts, free space)
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true   # don’t create .ds_store files on network volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true       # don’t create .ds_store files on usb volumes

# save & print panels
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true    # expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true   # expand save panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true       # expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true      # expand print panel by default

# screenshots
defaults write com.apple.screencapture type -string "png"                      # save screenshots as png

# textedit
defaults write com.apple.TextEdit RichText -int 0                              # use plain text by default in textedit

# security
defaults write com.apple.screensaver askForPassword -int 1                     # require password after sleep or screen saver begins
defaults write com.apple.screensaver askForPasswordDelay -int 0                # require password immediately

# disable all hot corners
for corner in tl tr bl br; do
  defaults write com.apple.dock wvous-$corner-corner -int 0
  defaults write com.apple.dock wvous-$corner-modifier -int 0
done

# restart affected processes
killall Dock Finder SystemUIServer
