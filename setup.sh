#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Enforce working directory to the script's location
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

# Parse --dry-run
DRY_RUN=false
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    DRY_RUN=true
    break
  fi
done

# Helper: run command or print what would be run
run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    info "Would run: $*"
  else
    "$@"
  fi
}

# Start script
banner "DOTFILES SETUP SCRIPT"
info "Starting dotfiles installation and system configuration..."
info "Working directory: $(pwd)"
info "Date: $(date '+%Y-%m-%d %H:%M:%S')"
[[ "$DRY_RUN" == true ]] && warning "DRY RUN MODE - no changes will be made"

banner "HOMEBREW INSTALLATION"
if ! command -v brew &>/dev/null; then
  if [[ "$DRY_RUN" == true ]]; then
    info "Would install Homebrew (https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    warning "Homebrew not found. Installing Homebrew..."
    warning "About to download and run the official Homebrew install script (https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)."
    warning "No checksum verification is performed; ensure you trust the source. Press Enter to continue or Ctrl+C to abort."
    read -r
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
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
  if [[ "$DRY_RUN" == true ]]; then
    info "Would install Nix (https://nixos.org/nix/install --daemon)"
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
fi

banner "HOMEBREW DEPENDENCIES"
info "Installing packages from Brewfile..."
if [[ -f ./Brewfile ]]; then
  run_cmd brew bundle --cleanup --file ./Brewfile
else
  warning "Brewfile not found, skipping Homebrew dependencies"
fi

banner "NPM GLOBAL PACKAGES"
if command -v npm &>/dev/null; then
  info "Installing global npm packages..."
  run_cmd npm install -g @anthropic-ai/claude-code @fsouza/prettierd eslint_d
else
  warning "npm not found, skipping global npm packages"
fi

banner "ZINIT INSTALLATION"
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ -d "$ZINIT_HOME" ]]; then
  info "Zinit is already installed at $ZINIT_HOME"
else
  info "Installing zinit plugin manager..."
  run_cmd mkdir -p "$(dirname "$ZINIT_HOME")"
  run_cmd git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  info "Zinit installed successfully"
fi

banner "GIT SUBMODULES"
info "Updating git submodules..."
run_cmd git submodule update --init --recursive
run_cmd git submodule update --remote --merge

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

	if [[ "$DRY_RUN" == true ]]; then
		if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
			info "Would backup $target and link $source -> $target"
		else
			info "Would link $source -> $target"
		fi
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
done < <(/usr/bin/find . -mindepth 1 -maxdepth 1 \( -type file -o -type link \) \( -name '.*' -o -name 'Brewfile' \) \! -name '.gitmodules')

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
	info "Installing Neovim plugins..."
	
	# Function to clean problematic plugins
	clean_problematic_plugins() {
		local lazy_dir="$HOME/.local/share/nvim/lazy"
		local cleaned=0
		
		if [[ -d "$lazy_dir" ]]; then
			# Check for plugins with local changes
			for plugin_dir in "$lazy_dir"/*; do
				if [[ -d "$plugin_dir/.git" ]]; then
					plugin_name=$(basename "$plugin_dir")
					
					# Check if there are local changes
					if ! git -C "$plugin_dir" diff --quiet 2>/dev/null || \
					   ! git -C "$plugin_dir" diff --cached --quiet 2>/dev/null || \
					   [[ -n $(git -C "$plugin_dir" status --porcelain 2>/dev/null) ]]; then
						warning "Found local changes in $plugin_name, cleaning..."
						if [[ "$DRY_RUN" != true ]]; then
							rm -rf "$plugin_dir"
						fi
						((cleaned++)) || true
					fi
				fi
			done
			
			if [[ $cleaned -gt 0 ]]; then
				info "Cleaned $cleaned plugin(s) with local changes"
			fi
		fi
	}
	
	# Clean any problematic plugins before sync
	clean_problematic_plugins

	run_cmd bash -c 'nvim --headless "+Lazy! sync" +qa' || true
else
	warning "Neovim not found, skipping plugin installation"
fi

banner "TMUX SETUP"
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
	info "Installing/updating tmux plugins..."
	# TPM scripts use 'tmux start-server; show-environment' to find the plugin path.
	# Set it directly in tmux's global environment so TPM can find it.
	run_cmd tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
	run_cmd "$TPM_DIR/bin/install_plugins"
	run_cmd "$TPM_DIR/bin/update_plugins" all
else
	warning "TPM not found (should be installed via git submodules), skipping"
fi

banner "SYSTEM CONFIGURATION"

info "Keyboard & Input Settings"
run_cmd defaults write -g InitialKeyRepeat -int 15
run_cmd defaults write -g KeyRepeat -int 2
run_cmd defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

info "Text & Typing Preferences"
run_cmd defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
run_cmd defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
run_cmd defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
run_cmd defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
run_cmd defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

info "Windows & Animations"
run_cmd defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
run_cmd defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
run_cmd defaults write -g QLPanelAnimationDuration -float 0

info "Mission Control & Spaces"
run_cmd defaults write com.apple.dock "expose-group-apps" -bool "true"
run_cmd defaults write com.apple.dock expose-animation-duration -float 0.1
run_cmd defaults write com.apple.spaces "spans-displays" -bool "true"

info "Dock Configuration"
run_cmd defaults write com.apple.dock autohide -bool true
run_cmd defaults write com.apple.dock autohide-delay -float 0
run_cmd defaults write com.apple.dock autohide-time-modifier -float 0.1
run_cmd defaults write com.apple.dock minimize-to-application -bool true
run_cmd defaults write com.apple.dock orientation -string "left"
run_cmd defaults write com.apple.dock springboard-show-duration -float 0.1
run_cmd defaults write com.apple.dock springboard-hide-duration -float 0.1
run_cmd defaults write com.apple.dock springboard-page-duration -float 0.1

info "Finder Preferences"
run_cmd defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run_cmd defaults write com.apple.finder AppleShowAllFiles -bool true
run_cmd defaults write com.apple.finder ShowPathbar -bool true
run_cmd defaults write com.apple.finder ShowStatusBar -bool true
run_cmd defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run_cmd defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

info "Save & Print Dialogs"
run_cmd defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run_cmd defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
run_cmd defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
run_cmd defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

info "Screenshot Settings"
run_cmd defaults write com.apple.screencapture type -string "png"

info "TextEdit Configuration"
run_cmd defaults write com.apple.TextEdit RichText -int 0

info "Security Settings"
run_cmd defaults write com.apple.screensaver askForPassword -int 1
run_cmd defaults write com.apple.screensaver askForPasswordDelay -int 0
if [[ "$DRY_RUN" == true ]]; then
  info "Would run: sudo defaults write ... LoginwindowSecurityImmediateLock (if permitted)"
elif sudo -n true 2>/dev/null; then
  sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowSecurityImmediateLock -bool true
elif sudo -v 2>/dev/null; then
  sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowSecurityImmediateLock -bool true
else
  warning "Skipping immediate-lock-on-sleep setting (requires administrator password). Run manually: sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowSecurityImmediateLock -bool true"
fi

info "Hot Corners"
for corner in tl tr bl br; do
  run_cmd defaults write com.apple.dock wvous-$corner-corner -int 0
  run_cmd defaults write com.apple.dock wvous-$corner-modifier -int 0
done

info "Restarting affected system processes..."
run_cmd bash -c 'killall Dock Finder SystemUIServer 2>/dev/null || true'

banner "SYSTEM CLEANUP"
if command -v mo &>/dev/null; then
	info "Running Mole cleanup..."
	run_cmd mo clean --yes
else
	warning "Mole (mo) not found, skipping system cleanup"
fi

banner "SETUP COMPLETE"
info "You may need to log out and back in for some changes to take full effect."
info "Script completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo
