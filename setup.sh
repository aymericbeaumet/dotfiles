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
skip() { info "Skipping: $1 (disabled via flag)"; }

# Error handler with enhanced output
trap 'error "Script failed at line $LINENO in $BASH_SOURCE"; exit 1' ERR

OS_NAME=$(uname -s 2>/dev/null || printf unknown)
IS_DARWIN=false
IS_DEBIAN=false
[[ "$OS_NAME" == "Darwin" ]] && IS_DARWIN=true
command -v apt-get &>/dev/null && IS_DEBIAN=true

# Section flags (all enabled by default)
DO_SSH=true
DO_APT=true
DO_HOMEBREW=true
DO_BREWFILE=true
DO_SYMLINKS=true
DO_NEOVIM=true
DO_ZSH=true
DO_TMUX=true
DO_MACOS=true
DO_PEON=true
DO_MISE=true

usage() {
  cat <<'USAGE'
Usage: setup.sh [OPTIONS]

Options:
  --no-ssh        Skip SSH key generation and GitHub authorization
  --no-apt        Skip Debian/Ubuntu system package installation
  --no-homebrew   Skip Homebrew installation
  --no-brewfile   Skip macOS software installation (Brewfile)
  --no-symlinks   Skip symlinking dotfiles
  --no-neovim     Skip Neovim plugin sync
  --no-zsh        Skip ZSH plugin installation
  --no-tmux       Skip tmux plugin installation
  --no-macos      Skip macOS defaults configuration
  --no-peon       Skip Peon sound pack installation
  --no-mise       Skip mise tool installation
  -h, --help      Show this help message
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --no-ssh) DO_SSH=false ;;
    --no-apt) DO_APT=false ;;
    --no-homebrew) DO_HOMEBREW=false ;;
    --no-brewfile) DO_BREWFILE=false ;;
    --no-symlinks) DO_SYMLINKS=false ;;
    --no-neovim) DO_NEOVIM=false ;;
    --no-zsh) DO_ZSH=false ;;
    --no-tmux) DO_TMUX=false ;;
    --no-macos) DO_MACOS=false ;;
    --no-peon) DO_PEON=false ;;
    --no-mise) DO_MISE=false ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $arg"
      usage >&2
      exit 1
      ;;
  esac
done

# Sections that only make sense on macOS auto-disable elsewhere. The Brewfile is
# intentionally macOS-only and must never run on Linux.
if ! $IS_DARWIN; then
  DO_HOMEBREW=false
  DO_BREWFILE=false
  DO_MACOS=false
fi

if $IS_DARWIN || ! $IS_DEBIAN; then
  DO_APT=false
fi

current_login_shell() {
  local user="$1"
  if $IS_DARWIN && command -v dscl &>/dev/null; then
    dscl . -read "/Users/$user" UserShell 2>/dev/null | awk '{print $2}' || true
  elif command -v getent &>/dev/null; then
    getent passwd "$user" 2>/dev/null | awk -F: '{print $7}' || true
  elif [[ -r /etc/passwd ]]; then
    awk -F: -v user="$user" '$1 == user {print $7; exit}' /etc/passwd || true
  else
    printf '%s\n' "${SHELL:-}"
  fi
}

preferred_zsh_path() {
  if $IS_DARWIN && [[ -x /bin/zsh ]]; then
    printf '%s\n' /bin/zsh
    return 0
  fi

  command -v zsh 2>/dev/null
}

ensure_shell_allowed() {
  local shell_path="$1"
  [[ -r /etc/shells ]] || return 0
  grep -Fxq "$shell_path" /etc/shells && return 0

  info "Adding zsh to /etc/shells: $shell_path"
  if [[ -w /etc/shells ]]; then
    if ! printf '%s\n' "$shell_path" >>/etc/shells; then
      warning "Failed to update /etc/shells; skipping default shell change"
      return 1
    fi
  elif command -v sudo &>/dev/null; then
    if ! printf '%s\n' "$shell_path" | sudo tee -a /etc/shells >/dev/null; then
      warning "Failed to update /etc/shells with sudo; skipping default shell change"
      return 1
    fi
  else
    warning "Cannot update /etc/shells without sudo; skipping default shell change"
    return 1
  fi
}

set_default_zsh_shell() {
  local user="${USER:-}"
  if [[ -z "$user" ]]; then
    warning "USER is not set; skipping default shell change"
    return 0
  fi

  local zsh_path
  zsh_path=$(preferred_zsh_path)
  if [[ -z "$zsh_path" ]]; then
    warning "zsh not found, skipping default shell change"
    return 0
  fi

  local current_shell
  current_shell=$(current_login_shell "$user")
  if [[ "${current_shell##*/}" == "zsh" ]]; then
    info "Default shell already set to zsh for $user: $current_shell"
    return 0
  fi

  if [[ "$current_shell" == "$zsh_path" ]]; then
    info "Default shell already set to zsh for $user: $zsh_path"
    return 0
  fi

  ensure_shell_allowed "$zsh_path" || return 0

  info "Setting default shell for $user to $zsh_path"
  if chsh -s "$zsh_path" "$user"; then
    info "Default shell updated; it will apply to the next login session"
  elif command -v sudo &>/dev/null && sudo chsh -s "$zsh_path" "$user"; then
    info "Default shell updated; it will apply to the next login session"
  else
    warning "Failed to change default shell to $zsh_path"
  fi
}

# Start script
banner "DOTFILES SETUP SCRIPT"
info "Starting dotfiles installation and system configuration..."
info "Working directory: $(pwd)"
info "Date: $(date '+%Y-%m-%d %H:%M:%S')"

banner "SETUP SSH"
if $DO_SSH; then

  # Ensure an SSH key exists for GitHub authentication
  SSH_KEY="$HOME/.ssh/id_ed25519"
  if [[ ! -f "$SSH_KEY" ]]; then
    info "No SSH key found at $SSH_KEY"
    info "Generating a new Ed25519 SSH key..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -C "$(whoami)@$(hostname)"
    info "SSH key generated successfully"
  else
    info "SSH key found at $SSH_KEY"
  fi

  # Check if the SSH key is already authorized on GitHub
  # Note: ssh -T always exits 1 (no shell access), so avoid pipefail by capturing output first
  SSH_TEST=$(ssh -T git@github.com 2>&1 || true)
  if echo "$SSH_TEST" | grep -q "successfully authenticated"; then
    info "SSH key is already authorized on GitHub"
  else
    echo
    info "Your public SSH key:"
    echo
    echo -e "  ${BOLD}$(cat "$SSH_KEY.pub")${NC}"
    echo
    info "Add it here: ${BOLD}https://github.com/settings/keys${NC}"
    echo
    warning "Press Enter once the key is added to GitHub..."
    read -r
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

else
  skip "SSH Key & Git Remote"
fi

banner "SETUP APT"
if $DO_APT; then

  if command -v apt-get &>/dev/null; then
    warning "Some steps require administrator privileges (sudo). You may be prompted for your password."
    sudo -v

    APT_PACKAGES=(
      bash
      build-essential
      ca-certificates
      curl
      git
      libpq-dev
      libreadline-dev
      libssl-dev
      lm-sensors
      pkg-config
      postgresql-client
      python3
      python3-pip
      python3-venv
      w3m
      wireguard-tools
      xdg-utils
      uuid-dev
      zlib1g-dev
      zsh
    )

    info "Installing Debian/Ubuntu bootstrap and system packages..."
    sudo apt-get update
    sudo apt-get install -y "${APT_PACKAGES[@]}"
  else
    warning "apt-get not found, skipping Debian/Ubuntu packages"
  fi

else
  skip "Debian/Ubuntu System Packages"
fi

banner "SETUP HOMEBREW"
if $DO_HOMEBREW; then

  if ! $IS_DARWIN; then
    warning "Homebrew bootstrap is macOS-only in this dotfiles setup"
  elif ! command -v brew &>/dev/null; then
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

  if $IS_DARWIN && command -v brew &>/dev/null; then
    for package in mise zsh; do
      if brew list --formula "$package" &>/dev/null; then
        info "Homebrew bootstrap package already installed: $package"
      else
        info "Installing Homebrew bootstrap package: $package"
        brew install "$package"
      fi
    done
  fi

else
  skip "Homebrew Installation"
fi

banner "SETUP MACOS SOFTWARE"
if $DO_BREWFILE; then

  if ! $IS_DARWIN; then
    warning "Brewfile is macOS-only; refusing to run it on $OS_NAME"
  elif ! command -v brew &>/dev/null; then
    warning "Homebrew not found, skipping Brewfile"
  elif [[ -f ./Brewfile ]]; then
    info "Installing macOS software from Brewfile..."
    if brew trust --help &>/dev/null; then
      while IFS= read -r tap_name; do
        [[ -n "$tap_name" ]] || continue
        info "Trusting Homebrew tap declared in Brewfile: $tap_name"
        brew trust --tap "$tap_name"
      done < <(awk -F"'" '/^tap / {print $2}' ./Brewfile)
    fi
    brew bundle install --no-upgrade --file ./Brewfile
  else
    warning "Brewfile not found, skipping Homebrew dependencies"
  fi

else
  skip "macOS Software"
fi

banner "SETUP MISE"
if $DO_MISE; then

  if ! command -v mise &>/dev/null; then
    if $IS_DARWIN && command -v brew &>/dev/null; then
      info "Installing mise with Homebrew bootstrap..."
      brew install mise
    elif command -v curl &>/dev/null; then
      warning "mise not found. About to download and run the official mise installer (https://mise.run)."
      warning "No checksum verification is performed; ensure you trust the source. Press Enter to continue or Ctrl+C to abort."
      read -r
      curl -fsSL https://mise.run | sh
      export PATH="$HOME/.local/bin:$PATH"
    else
      warning "mise and curl not found, skipping tool installation"
    fi
  fi

  if command -v mise &>/dev/null; then
    mise_source_config="$PWD/.config/mise/config.toml"
    if [[ ! -f "$mise_source_config" ]]; then
      warning "mise config not found at $mise_source_config"
    fi

    # Override the config's `offline = true` (which keeps the shell prompt from
    # hitting GitHub on every precmd). setup.sh is the explicit install/upgrade
    # path and must be allowed to resolve `latest` and download tool releases.
    export MISE_OFFLINE=0

    if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null; then
      if token=$(gh auth token 2>/dev/null) && [[ -n "$token" ]]; then
        export GITHUB_TOKEN="$token"
        info "Using GitHub token from gh for mise release downloads"
      fi
    fi

    install_mise_bootstrap_tool() {
      local tool="$1"
      if ! grep -Eq "^[[:space:]]*$tool[[:space:]]*=" "$mise_source_config" 2>/dev/null; then
        return 0
      fi

      info "Installing mise bootstrap tool: $tool..."
      mise install "$tool"
      export PATH="$HOME/.local/share/mise/shims:$PATH"
      mise reshim "$tool" >/dev/null 2>&1 || true
      hash -r 2>/dev/null || true
    }

    # pipx must exist before mise install runs so pipx:* backends resolve.
    export PIPX_DEFAULT_BACKEND="${PIPX_DEFAULT_BACKEND:-pip}"
    install_mise_bootstrap_tool pipx

    info "Installing mise tools from global config..."
    if ! mise install; then
      warning "Some mise tools failed to install; continuing with available tools"
    fi
    export PATH="$HOME/.local/share/mise/shims:$PATH"
    info "Pruning mise tools not listed in config..."
    if ! mise prune --yes; then
      warning "mise prune failed; continuing"
    fi
  else
    warning "mise not found, skipping tool installation"
  fi

else
  skip "Mise Tool Installation"
fi

banner "SETUP SYMLINKS"
if $DO_SYMLINKS; then

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
  done < <(/usr/bin/find . -mindepth 1 -maxdepth 1 \( -type f -o -type l \) \( -name '.*' -o -name 'Brewfile' \))

  # Symlink hidden directories
  info "Linking hidden directories..."
  while IFS= read -r dir; do
    symlink "${dir#./}"
  done < <(/usr/bin/find . -mindepth 1 -maxdepth 1 -type d -name '.*' \! -name '.config' \! -name '.git')

  # Symlink .config directories
  if [[ -d .config ]]; then
    info "Linking .config directories..."
    while IFS= read -r dir; do
      symlink "$dir"
    done < <(/usr/bin/find .config -mindepth 1 -maxdepth 1 -type d)
  else
    info "No .config directory found, skipping"
  fi

else
  skip "Symlinking Dotfiles"
fi

banner "SETUP NEOVIM"
if $DO_NEOVIM; then

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

    # lazy.nvim auto-installs from init.lua, then syncs all plugins.
    # After Lazy sync, block until mason-tool-installer's background installs
    # finish — otherwise +qa aborts mid-install (delve, codelldb, etc).
    info "Syncing Neovim plugins (lazy.nvim + Mason)..."
    bash -c 'nvim --headless \
        "+Lazy! sync" \
        +"lua vim.wait(300000, function() local ok, r = pcall(require, \"mason-registry\"); if not ok then return true end; for _, p in ipairs(r.get_installed_packages()) do if p:is_installing() then return false end end; return true end, 250)" \
        +qa' || true
  else
    warning "Neovim not found, skipping plugin installation"
  fi

else
  skip "Neovim Setup"
fi

banner "SETUP ZSH"
if $DO_ZSH; then

  if command -v zsh &>/dev/null; then
    set_default_zsh_shell

    # zinit auto-installs from .zshrc; interactive mode sources plugin definitions,
    # then burst the scheduler to force turbo-mode plugins to load at once
    info "Installing zsh plugins (zinit bootstraps from .zshrc)..."
    zsh -ic '@zinit-scheduler burst || true' 2>/dev/null || true
  else
    warning "zsh not found, skipping plugin installation"
  fi

else
  skip "ZSH Plugins"
fi

banner "SETUP TMUX"
if $DO_TMUX; then

  if command -v tmux &>/dev/null; then
    # Clone TPM directly rather than relying on the async if-shell hook in
    # .tmux.conf. The hook still acts as a fallback for users who never run
    # setup.sh, but doing it here removes the race that left TPM half-installed
    # when tmux new-session returned.
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
      info "Cloning TPM into $TPM_DIR..."
      git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi

    info "Installing tmux plugins (TPM bootstraps from .tmux.conf)..."
    tmux new-session -d -s __setup__

    if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
      "$TPM_DIR/bin/install_plugins"
      "$TPM_DIR/bin/update_plugins" all
    else
      warning "TPM not available at $TPM_DIR after clone attempt"
    fi

    tmux kill-session -t __setup__ 2>/dev/null || true
  else
    warning "tmux not found, skipping plugin installation"
  fi

else
  skip "Tmux Setup"
fi

banner "SETUP MACOS"
if $DO_MACOS; then

  warning "Some steps require administrator privileges (sudo). You may be prompted for your password."
  sudo -v

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

  info "Menu Bar"
  defaults write NSGlobalDomain _HIHideMenuBar -bool true

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

  # Free up Cmd+Shift+1/2/3 for terminal use (tmux session-switch via Alacritty).
  # Only Cmd+Shift+3 is claimed by macOS (symbolic hotkey 28 = "Save picture of
  # screen as a file"); 1 and 2 have no default global binding. Disabling
  # requires logout/login (or restart of cfprefsd) to take effect.
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 28 \
    '{enabled = 0; value = { parameters = (51, 20, 1179648); type = standard; }; }'

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

else
  skip "System Configuration"
fi

banner "SETUP PEON"
if $DO_PEON; then

  if command -v peon &>/dev/null; then
    PEON_PACKS="peasant_fr"
    info "Installing Peon sound packs: $PEON_PACKS"
    peon packs install "$PEON_PACKS" | cat
    info "Setting active pack to peasant_fr..."
    peon packs use peasant_fr | cat
  else
    warning "Peon not found, skipping sound pack installation"
  fi

else
  skip "Peon Sound Packs"
fi

banner "SETUP COMPLETE"
info "You may need to log out and back in for some changes to take full effect."
info "Script completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo
