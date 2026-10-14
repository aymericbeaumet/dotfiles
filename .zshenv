# Author: Aymeric Beaumet <hi@aymericbeaumet.com>
# Github: @aymericbeaumet/dotfiles

# the startup files /etc/zprofile, /etc/zshrc, /etc/zlogin and /etc/zlogout will not be run
setopt noglobalrcs

# Source a tool's shell integration from a cache under ~/.cache/zsh. Running the
# generator spawns the tool (10-70 ms each per shell); sourcing the cached output
# costs about nothing. The cache is rebuilt when the binary is newer than it or
# the generator command line changed. See docs/zsh-performance.md.
# Usage: _dotfiles_cached_source <name> <binary> <generator...>
_dotfiles_cached_source() {
  local name=$1 bin=$2 cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$1.zsh" header
  shift 2
  [[ $bin == */* ]] || bin=${commands[$bin]:-$bin}
  if [[ -s $cache && ! $bin -nt $cache ]] && IFS= read -r header < "$cache" &&
     [[ $header == "# $*" ]]; then
    source "$cache"
    return
  fi
  [[ -d ${cache:h} ]] || command mkdir -p -- "${cache:h}"
  { print -r -- "# $*" && "$@" } > "$cache.$$" && command mv -f -- "$cache.$$" "$cache" ||
    { command rm -f -- "$cache.$$"; return 1 }
  source "$cache"
}

# load secret env files
if [[ -f "$HOME/.zshsecret" ]]; then
  source "$HOME/.zshsecret"
fi
