#!/bin/sh
# Read text from stdin, extract the first likely URL, and open it.
set -eu

. "${DOTFILES:-$HOME/.dotfiles}/scripts/lib.sh"

input=$(cat 2>/dev/null || true)
[ -n "$input" ] || exit 0

url=$(printf '%s\n' "$input" |
  awk '
    {
      for (i = 1; i <= NF; i++) {
        token = $i
        gsub(/^[<({["'\''`]+/, "", token)
        gsub(/[>)}\]"'\''`,.;:]+$/, "", token)
        if (token ~ /^(https?|file):\/\// || token ~ /^[A-Za-z0-9._-]+\.[A-Za-z]{2,}(\/[^[:space:]]*)?$/) {
          print token
          exit
        }
      }
    }')

[ -n "$url" ] || exit 0

case "$url" in
  http://*|https://*|file://*) ;;
  *) url="https://$url" ;;
esac

"$(dotfiles_dir)/scripts/open-url.sh" "$url"
