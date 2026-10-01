#!/bin/sh
# Docker status for the Flash status bar: a running-container count for the
# label, and a compact container table for the popup behind it.
#
# Flash is a GUI app, so it starts from a minimal PATH carrying neither mise nor
# Homebrew, and the Docker CLI is mise-managed. Resolve it here rather than
# relying on an inherited login environment.
set -eu

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

# Nord, matching the status bar: yellow headings, green healthy, red stopped,
# grey for the detail columns.
render() {
  docker ps --format '{{.Names}}	{{.Status}}	{{.Ports}}	{{.Image}}' 2>/dev/null |
    LC_ALL=C.UTF-8 awk -F'\t' -v now="$(date '+%H:%M:%S')" '
      function trunc(s, w) { return length(s) > w ? substr(s, 1, w - 1) "…" : s }
      # awk pads by bytes, and the glyphs below cost three bytes for one column,
      # so every one of them would shorten its column. Pad by display width.
      function extra(s,   t) { t = s; return 2 * (gsub(/→/, "", t) + gsub(/…/, "", t)) }
      function padr(s, w,   n, p) {
        n = w + extra(s) - length(s); p = ""
        while (n-- > 0) p = p " "
        return s p
      }
      # Only published ports say anything useful from outside the VM, and the
      # bind address repeats on every row. Keep host→container.
      function ports(p,   n, a, i, s, hc, h, c, out) {
        n = split(p, a, /, */); out = ""
        for (i = 1; i <= n; i++) {
          if (a[i] !~ /->/) continue
          s = a[i]; sub(/\/[a-z]+$/, "", s)
          split(s, hc, "->"); h = hc[1]; c = hc[2]; sub(/^.*:/, "", h)
          out = out (out == "" ? "" : " ") (h == c ? h : h "→" c)
        }
        return out
      }
      BEGIN {
        R = "\033[0m"; Y = "\033[38;2;235;203;139m"; G = "\033[38;2;163;190;140m"
        E = "\033[38;2;191;97;106m"; D = "\033[38;5;245m"; F = "\033[38;2;216;222;233m"
        printf "%s%-22s %-13s %-28s %s%s\n", Y "\033[1m", "NAME", "STATUS", "PORTS", "IMAGE", R
        rows = 0
      }
      {
        rows++
        name = $1; st = $2; prt = ports($3); img = $4
        # Duration: first number plus the unit initial, so "19 hours" is "19h".
        dur = ""
        if (match(st, /[0-9]+ [a-z]+/)) {
          split(substr(st, RSTART, RLENGTH), dw, " ")
          dur = dw[1] substr(dw[2], 1, 1)
        }
        if (st ~ /^Up/) {
          if (st ~ /unhealthy/)            { col = Y; word = "up " dur " !" }
          else if (st ~ /health: starting/) { col = Y; word = "up " dur " ~" }
          else                              { col = G; word = "up " dur }
        } else {
          col = E
          word = tolower(st); sub(/ .*/, "", word); word = word " " dur
        }
        printf "%s%s%s %s%s%s %s%s%s %s%s%s\n", \
          F, padr(trunc(name, 22), 22), R, col, padr(word, 13), R, \
          D, padr(trunc(prt, 28), 28), R, D, trunc(img, 34), R
      }
      END {
        if (rows == 0) { printf "%sno running containers%s\n", D, R; exit }
        printf "%s%d running · %s%s\n", D, rows, now, R
      }
    '
}

case "${1:-count}" in
  count)
    # A stopped Colima means no daemon at all. Report zero rather than letting a
    # connection error reach the bar; the popup explains why when asked.
    docker ps -q 2>/dev/null | wc -l | tr -d ' '
    ;;
  ps)
    if ! docker info >/dev/null 2>&1; then
      printf '\033[38;2;191;97;106mdocker unavailable: is colima running? (colima start)\033[0m\n'
      exit 0
    fi
    render
    ;;
  watch)
    # Flash keeps this popup resident, and a resident popup shows whatever its
    # process last drew. Redraw on a timer so hovering never serves a snapshot
    # taken when Flash started, which is also what left the screen mostly blank.
    while :; do
      printf '\033[H\033[2J'
      "$0" ps
      sleep "${DOCKER_STATUS_INTERVAL:-10}"
    done
    ;;
  *)
    printf 'usage: docker-status.sh [count|ps|watch]\n' >&2
    exit 1
    ;;
esac
