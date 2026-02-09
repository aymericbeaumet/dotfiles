#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Enforce working directory to the script's location
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Color definitions
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Log functions
banner() {
  echo
  echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
  printf "${BLUE}${BOLD}║${NC} ${CYAN}${BOLD}%-64s ${BLUE}${BOLD}║${NC}\n" "$1"
  echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
  echo
}
info() { echo -e "${CYAN}  ℹ${NC} $1"; }
warning() { echo -e "${YELLOW}  ⚠${NC} $1"; }
error() { echo -e "${RED}  ✗${NC} $1" >&2; }

# Error handler with enhanced output
trap 'error "Script failed at line $LINENO in $BASH_SOURCE"; exit 1' ERR

# Start script
banner "DOTFILES SETUP SCRIPT"
info "Starting dotfiles installation and system configuration..."
info "Working directory: $(pwd)"
info "Date: $(date '+%Y-%m-%d %H:%M:%S')"

banner "SSH KEY & GIT REMOTE"

# Ensure an SSH key exists for GitHub authentication
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  info "No SSH key found at $SSH_KEY"
  info "Generating a new Ed25519 SSH key..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$SSH_KEY" -C "$(whoami)@$(hostname)"
  info "SSH key generated successfully"
  echo
  info "Your public SSH key:"
  echo
  echo -e "  ${BOLD}$(cat "$SSH_KEY.pub")${NC}"
  echo
  info "Add it here: ${BOLD}https://github.com/settings/keys${NC}"
  echo
  warning "Press Enter once the key is added to GitHub..."
  read -r
else
  info "SSH key found at $SSH_KEY"
fi

# Switch the dotfiles remote from HTTPS (read-only clone) to SSH (read-write)
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || true)
SSH_REMOTE="git@github.com:aymericbeaumet/dotfiles.git"
if [[ "$CURRENT_REMOTE" != "$SSH_REMOTE" ]]; then
  info "Switching git remote from HTTPS to SSH..."
  git remote set-url origin "$SSH_REMOTE"
  info "Remote origin updated to $SSH_REMOTE"
else
  info "Git remote already set to SSH: $SSH_REMOTE"
fi

banner "HOMEBREW INSTALLATION"
if ! command -v brew &>/dev/null; then
  warning "Homebrew not found. Installing Homebrew..."
  warning "About to download and run the official Homebrew install script (https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)."
  warning "No checksum verification is performed; ensure you trust the source. Press Enter to continue or Ctrl+C to abort."
  read -r
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew is already installed at $(which brew)"
  info "Homebrew version: $(brew --version | head -n1)"
fi

banner "NIX INSTALLATION"
# Check for Nix installation via command, /nix directory, or backup files
if command -v nix &>/dev/null; then
  info "Nix is already installed at $(which nix)"
  info "Nix version: $(nix --version)"
elif [[ -d /nix ]] || [[ -e /etc/bashrc.backup-before-nix ]] || [[ -e /etc/zshrc.backup-before-nix ]]; then
  warning "Nix installation detected but not in PATH"
  info "Sourcing Nix profile..."
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    info "Nix version: $(nix --version 2>/dev/null || echo 'unknown')"
  else
    warning "Could not source Nix profile, but Nix appears to be installed"
  fi
else
  warning "Nix not found. Installing Nix..."
  warning "About to download and run the official Nix install script (https://nixos.org/nix/install)."
  warning "No checksum verification is performed; ensure you trust the source. Press Enter to continue or Ctrl+C to abort."
  read -r
  curl -L https://nixos.org/nix/install | sh -s -- --daemon
  # Source nix profile for current session
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

banner "HOMEBREW DEPENDENCIES"
info "Installing packages from Brewfile..."
if [[ -f ./Brewfile ]]; then
  brew bundle --cleanup --file ./Brewfile
else
  warning "Brewfile not found, skipping Homebrew dependencies"
fi

banner "NPM GLOBAL PACKAGES"
if command -v npm &>/dev/null; then
  info "Installing global npm packages..."
  npm install -g @anthropic-ai/claude-code @fsouza/prettierd eslint_d
else
  warning "npm not found, skipping global npm packages"
fi

banner "SYMLINKING DOTFILES"
info "Creating symbolic links for configuration files..."

symlink() {
  local source="$1"
  local target="$HOME/$1"
  local want_link="$PWD/$source"

  # Skip if symlink already points to the correct target
  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$want_link" ]]; then
    info "Symlink already correct: $target"
    return 0
  fi

  # Backup existing non-symlink file or directory before overwriting
  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    local backup="${target}.bak.$(date +%s)"
    warning "Backing up existing: $target -> $backup"
    mv "$target" "$backup"
  fi

  # Remove existing symlink if it points elsewhere
  if [[ -L "$target" ]]; then
    rm -f "$target"
  fi

  mkdir -p "$(dirname "$target")"
  ln -sf "$want_link" "$target"
}

# Symlink dotfiles and Brewfile
info "Linking dotfiles and Brewfile..."
while IFS= read -r file; do
  symlink "${file#./}"
done < <(/usr/bin/find . -mindepth 1 -maxdepth 1 \( -type file -o -type link \) \( -name '.*' -o -name 'Brewfile' \))

# Symlink hidden directories
info "Linking hidden directories..."
while IFS= read -r dir; do
  symlink "${dir#./}"
done < <(/usr/bin/find . -mindepth 1 -maxdepth 1 -type dir -name '.*' \! -name '.config' \! -name '.git')

# Symlink .config directories
if [[ -d .config ]]; then
  info "Linking .config directories..."
  while IFS= read -r dir; do
    symlink "$dir"
  done < <(/usr/bin/find .config -mindepth 1 -maxdepth 1 -type dir)
else
  info "No .config directory found, skipping"
fi

banner "NEOVIM SETUP"
if command -v nvim &>/dev/null; then
  # Clean plugins with local changes before sync (prevents merge conflicts)
  LAZY_PLUGINS_DIR="$HOME/.local/share/nvim/lazy"
  if [[ -d "$LAZY_PLUGINS_DIR" ]]; then
    cleaned=0
    for plugin_dir in "$LAZY_PLUGINS_DIR"/*/; do
      [[ -d "$plugin_dir/.git" ]] || continue
      if ! git -C "$plugin_dir" diff --quiet 2>/dev/null ||
        ! git -C "$plugin_dir" diff --cached --quiet 2>/dev/null ||
        [[ -n $(git -C "$plugin_dir" status --porcelain 2>/dev/null) ]]; then
        warning "Found local changes in $(basename "$plugin_dir"), cleaning..."
        rm -rf "$plugin_dir"
        ((cleaned++)) || true
      fi
    done
    [[ $cleaned -gt 0 ]] && info "Cleaned $cleaned plugin(s) with local changes"
  fi

  # lazy.nvim auto-installs from init.lua, then syncs all plugins
  info "Syncing Neovim plugins (lazy.nvim bootstraps from init.lua)..."
  bash -c 'nvim --headless "+Lazy! sync" +qa' || true
else
  warning "Neovim not found, skipping plugin installation"
fi

banner "ZSH PLUGINS"
if command -v zsh &>/dev/null; then
  # zinit auto-installs from .zshrc; interactive mode sources plugin definitions,
  # then burst the scheduler to force turbo-mode plugins to install immediately
  info "Installing zsh plugins (zinit bootstraps from .zshrc)..."
  zsh -ic '@zinit-scheduler burst || true'
else
  warning "zsh not found, skipping plugin installation"
fi

banner "TMUX SETUP"
if command -v tmux &>/dev/null; then
  # TPM auto-installs from .tmux.conf; start a detached session to trigger it,
  # then wait-for the deterministic signal sent at the end of .tmux.conf
  info "Installing tmux plugins (TPM bootstraps from .tmux.conf)..."
  tmux new-session -d -s __setup__
  tmux wait-for tpm-ready

  TPM_DIR="$HOME/.tmux/plugins/tpm"
  if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
    "$TPM_DIR/bin/install_plugins"
    "$TPM_DIR/bin/update_plugins" all
  else
    warning "TPM not available after sourcing .tmux.conf"
  fi

  tmux kill-session -t _setup 2>/dev/null || true
else
  warning "tmux not found, skipping plugin installation"
fi

banner "SYSTEM CONFIGURATION"

info "Keyboard & Input Settings"
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

info "Text & Typing Preferences"
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

info "Windows & Animations"
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write -g QLPanelAnimationDuration -float 0

info "Mission Control & Spaces"
defaults write com.apple.dock "expose-group-apps" -bool "true"
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.spaces "spans-displays" -bool "true"

info "Dock Configuration"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.1
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock orientation -string "left"
defaults write com.apple.dock springboard-show-duration -float 0.1
defaults write com.apple.dock springboard-hide-duration -float 0.1
defaults write com.apple.dock springboard-page-duration -float 0.1

info "Finder Preferences"
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

info "Save & Print Dialogs"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

info "Screenshot Settings"
defaults write com.apple.screencapture type -string "png"

info "TextEdit Configuration"
defaults write com.apple.TextEdit RichText -int 0

info "Security Settings"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowSecurityImmediateLock -bool true

info "Hot Corners"
for corner in tl tr bl br; do
  defaults write com.apple.dock wvous-$corner-corner -int 0
  defaults write com.apple.dock wvous-$corner-modifier -int 0
done

info "Restarting affected system processes..."
bash -c 'killall Dock Finder SystemUIServer 2>/dev/null || true'

banner "SYSTEM CLEANUP"
if command -v mo &>/dev/null; then
  info "Running Mole cleanup..."
  mo clean --yes
else
  warning "Mole (mo) not found, skipping system cleanup"
fi

banner "SETUP COMPLETE"
info "You may need to log out and back in for some changes to take full effect."
info "Script completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo
