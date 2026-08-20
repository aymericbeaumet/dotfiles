# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# the startup files /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout will not be run
setopt noglobalrcs

# OpenCode reads AGENTS.md and .agents/skills natively. Disable its Claude
# compatibility fallback so the .claude adapter is not discovered a second time.
export OPENCODE_DISABLE_CLAUDE_CODE=1

# mise owns Pi upgrades, so skip its independent startup version check.
export PI_SKIP_VERSION_CHECK=1

# load secret env files
if [[ -f "$HOME/.zshsecret" ]]; then
  source "$HOME/.zshsecret"
fi
