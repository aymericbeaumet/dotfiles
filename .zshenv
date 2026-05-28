# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# the startup files /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout will not be run
setopt noglobalrcs

# load secret env files
if [[ -f "$HOME/.zshsecret" ]]; then
  source "$HOME/.zshsecret"
fi
