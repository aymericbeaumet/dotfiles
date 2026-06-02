#!/bin/sh
# VPN status labels for tmux. Colour matches the existing internet/battery rule:
# colour178 when the VPN process is present, red otherwise.
# Pass a 3rd arg to make the label a clickable tmux range (see status-click.sh).

ok=colour178
bad=red

vpn_status() {
  label="$1"
  pattern="$2"
  range="${3:-}"

  if pgrep -f "$pattern" >/dev/null 2>&1; then
    color=$ok
  else
    color=$bad
  fi

  if [ -n "$range" ]; then
    printf '#[range=user|%s fg=%s]%s#[norange]' "$range" "$color" "$label"
  else
    printf '#[fg=%s]%s' "$color" "$label"
  fi
}

sep='#[fg=colour240] · '
vpn_status aws '[a]cvc-openvpn' app-aws
printf '%s' "$sep"
vpn_status moria '[m]oria'
printf '%s' "$sep"
vpn_status proton '[c]h\.protonvpn\.mac\.(WireGuard-Extension|Transparent-Proxy)|[P]rotonVPN.*(WireGuard|OpenVPN|Tunnel|Extension)' app-proton
