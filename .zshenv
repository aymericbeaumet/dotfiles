# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# the startup files /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout will not be run
setopt noglobalrcs

# nix (noglobalrcs skips /etc/zshenv where nix-darwin normally initializes)
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  unset __ETC_PROFILE_NIX_SOURCED
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# load secret env files
if [[ -f "$HOME/.zshsecret" ]]; then
  source "$HOME/.zshsecret"
fi
