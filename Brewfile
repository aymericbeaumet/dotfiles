# macOS-only software only.
# setup.sh never runs this file on Linux. Cross-platform user-facing CLIs
# belong in .config/mise/config.toml, and OS/system packages belong in setup.sh.

tap 'tw93/tap'

# Bootstrap formulae (also ensured early in setup.sh). Listed here so
# `brew bundle cleanup` keeps them instead of uninstalling them. These are
# bootstrappers, not the user CLIs that belong in .config/mise/config.toml.
brew 'mise'
brew 'zsh'

# macOS-only tools
brew 'macmon'
brew 'nowplaying-cli'
brew 'tw93/tap/mole'

# macOS GUI applications
cask 'alacritty'
cask 'aws-vpn-client'
cask 'cursor'
cask 'db-browser-for-sqlite'
cask 'figma'
cask 'firefox'
cask 'firefox@developer-edition'
cask 'font-fira-code-nerd-font'
cask 'google-chrome'
cask 'google-drive'
cask 'karabiner-elements'
cask 'linear'
cask 'notion'
cask 'postico'
cask 'postman'
cask 'prismlauncher'
cask 'protonvpn'
cask 'slack'
cask 'spotify'
cask 'transmission'
cask 'utm'
cask 'vlc'
cask 'whatsapp'
cask 'zoom'
