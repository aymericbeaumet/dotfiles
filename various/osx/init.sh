# Thanks: https://github.com/mathiasbynens/dotfiles/blob/master/.osx

# General UI/UX

echo 'Hide the Spotlight icon'
sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search

echo 'Disable the sound effects on boot'
sudo nvram SystemAudioVolume=' '

echo 'Increase window resize speed for Cocoa applications'
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

echo 'Expand save panel by default'
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

echo 'Expand print panel by default'
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

echo 'Automatically quit printer app once the print jobs complete'
defaults write com.apple.print.PrintingPrefs 'Quit When Finished' -bool true

echo 'Disable the “Are you sure you want to open this application?” dialog'
defaults write com.apple.LaunchServices LSQuarantine -bool false

echo 'Disable the crash reporter'
defaults write com.apple.CrashReporter DialogType -string 'none'

echo 'Restart automatically if the computer freezes'
sudo systemsetup -setrestartfreeze on

echo 'Never go into computer sleep mode'
sudo systemsetup -setcomputersleep Off > /dev/null

echo 'Check for software updates daily, not just once per week'
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

echo 'Set the timezone'
sudo systemsetup -settimezone 'Europe/Paris' > /dev/null

# SSD-specific tweaks

echo 'Disable local Time Machine snapshots'
sudo tmutil disablelocal

echo 'Disable hibernation (speeds up entering sleep mode)'
sudo pmset -a hibernatemode 0

echo 'Remove the sleep image file to save disk space'
sudo rm /Private/var/vm/sleepimage
echo 'Create a zero-byte file instead...'
sudo touch /Private/var/vm/sleepimage
echo '...and make sure it can’t be rewritten'
sudo chflags uchg /Private/var/vm/sleepimage

echo 'Disable the sudden motion sensor as it’s not useful for SSDs'
sudo pmset -a sms 0

# Trackpad, mouse, keyboard, Bluetooth accessories, and input

echo 'Trackpad: enable tap to click for this user and for the login screen'
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

echo 'Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)'
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo 'Disable auto-correct'
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Screen

echo 'Require password immediately after sleep or screen saver begins'
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

echo 'Save screenshots to the appropriate Dropbox folder'
defaults write com.apple.screencapture location -string "${HOME}/Dropbox/Screenshots"

echo 'Save screenshots in PNG format'
defaults write com.apple.screencapture type -string 'png'

echo 'Disable shadow in screenshots'
defaults write com.apple.screencapture disable-shadow -bool true

echo 'Enable subpixel font rendering on non-Apple LCDs'
defaults write NSGlobalDomain AppleFontSmoothing -int 2

echo 'Enable HiDPI display modes'
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

# Finder

echo 'Disable window animations and Get Info animations'
defaults write com.apple.finder DisableAllAnimations -bool true

echo 'Set Home as the default location for new Finder windows'
defaults write com.apple.finder NewWindowTarget -string 'PfLo'
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

echo 'Show icons for hard drives, servers, and removable media on the desktop'
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

echo 'Show all filename extensions'
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo 'Show status bar'
defaults write com.apple.finder ShowStatusBar -bool true

echo 'Show path bar'
defaults write com.apple.finder ShowPathbar -bool true

echo 'Allow text selection in Quick Look'
defaults write com.apple.finder QLEnableTextSelection -bool true

echo 'Display full POSIX path as Finder window title'
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

echo 'When performing a search, search the current folder by default'
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

echo 'Disable the warning when changing a file extension'
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

echo 'Enable spring loading for directories'
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

echo 'Remove the spring loading delay for directories'
defaults write NSGlobalDomain com.apple.springing.delay -float 0

echo 'Avoid creating .DS_Store files on network volumes'
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo 'Disable disk image verification'
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

echo 'Automatically open a new Finder window when a volume is mounted'
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

echo 'Show item info near icons on the desktop and in other icon views'
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist

echo 'Show item info to the right of the icons on the desktop'
/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false" ~/Library/Preferences/com.apple.finder.plist

echo 'Enable snap-to-grid for icons on the desktop and in other icon views'
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

echo 'Increase grid spacing for icons on the desktop and in other icon views'
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

echo 'Increase the size of icons on the desktop and in other icon views'
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist

echo 'Use list view in all Finder windows by default'
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

echo 'Disable the warning before emptying the Trash'
defaults write com.apple.finder WarnOnEmptyTrash -bool false

echo 'Empty Trash securely by default'
defaults write com.apple.finder EmptyTrashSecurely -bool true

echo 'Enable AirDrop over Ethernet'
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

echo 'Enable the MacBook Air SuperDrive on any Mac'
sudo nvram boot-args="mbasd=1"

echo 'Show the ~/Library folder'
chflags nohidden ~/Library

echo 'Expand the following File Info panes: “General”, “Open with”, and “Sharing & Permissions”'
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true \
	Privileges -bool true

# Dock, Dashboard, and hot corners

echo 'Enable highlight hover effect for the grid view of a stack (Dock)'
defaults write com.apple.dock mouse-over-hilite-stack -bool true

echo 'Set the icon size of Dock items to 36 pixels'
defaults write com.apple.dock tilesize -int 36

echo 'Change minimize/maximize window effect'
defaults write com.apple.dock mineffect -string "scale"

echo 'Minimize windows into their application’s icon'
defaults write com.apple.dock minimize-to-application -bool true

echo 'Enable spring loading for all Dock items'
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

echo 'Show indicator lights for open applications in the Dock'
defaults write com.apple.dock show-process-indicators -bool true

echo 'Don’t animate opening applications from the Dock'
defaults write com.apple.dock launchanim -bool false

echo 'Remove the auto-hiding Dock delay'
defaults write com.apple.dock autohide-delay -float 0
echo 'Remove the animation when hiding/showing the Dock'
defaults write com.apple.dock autohide-time-modifier -float 0

echo 'Automatically hide and show the Dock'
defaults write com.apple.dock autohide -bool true

echo 'Make Dock icons of hidden applications translucent'
defaults write com.apple.dock showhidden -bool true

echo 'Disable the Launchpad gesture (pinch with thumb and three fingers)'
defaults write com.apple.dock showLaunchpadGestureEnabled -int 0

echo 'Hot corners'
defaults write com.apple.dock wvous-tl-corner -int 5
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 12
defaults write com.apple.dock wvous-tr-modifier -int 0

# Time Machine

echo 'Prevent Time Machine from prompting to use new hard drives as backup volume'
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

echo 'Disable local Time Machine backups'
hash tmutil &> /dev/null && sudo tmutil disablelocal

# Activity Monitor

echo 'Show the main window when launching Activity Monitor'
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

echo 'Visualize CPU usage in the Activity Monitor Dock icon'
defaults write com.apple.ActivityMonitor IconType -int 5

echo 'Show all processes in Activity Monitor'
defaults write com.apple.ActivityMonitor ShowCategory -int 0

echo 'Sort Activity Monitor results by CPU usage'
defaults write com.apple.ActivityMonitor SortColumn -string 'CPUUsage'
defaults write com.apple.ActivityMonitor SortDirection -int 0
