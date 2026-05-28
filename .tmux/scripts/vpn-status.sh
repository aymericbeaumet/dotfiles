#!/bin/sh
# VPN status labels for tmux. Colour matches the existing internet/battery rule:
# colour178 when the VPN process is present, red otherwise.

ok=colour178
bad=red

vpn_status() {
  label="$1"
  pattern="$2"

  if pgrep -f "$pattern" >/dev/null 2>&1; then
    printf '#[fg=%s]%s' "$ok" "$label"
  else
    printf '#[fg=%s]%s' "$bad" "$label"
  fi
}

vpn_status awsvpn '[a]cvc-openvpn'
printf '#[fg=colour178] │ '
vpn_status protonvpn '[c]h\.protonvpn\.mac\.(WireGuard-Extension|Transparent-Proxy)|[P]rotonVPN.*(WireGuard|OpenVPN|Tunnel|Extension)'
