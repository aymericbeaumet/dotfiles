#!/bin/sh
# Print an "[ssh] <destination>" label for a tmux pane running ssh.
# Usage: tmux-ssh-info.sh <pane_pid>
#
# Called from pane-border-format via #() only for panes whose
# pane_current_command is ssh (tmux short-circuits the other branches), so the
# ps walk below runs solely for ssh panes. We locate the ssh process nearest the
# pane shell (so a ProxyJump/-W child ssh doesn't shadow the real destination)
# and heuristically extract its [user@]host argument by skipping option flags.
#
# Limitation: ps flattens argv on whitespace, so an option value containing a
# space (e.g. -o ProxyCommand='sleep 1') can mislead the destination heuristic.
# Interactive `ssh [user@]host [-p N] ...` invocations parse correctly.

root="${1:-}"
case "$root" in
  '' | *[!0-9]*)
    printf '[ssh]'
    exit 0
    ;;
esac

# pid ppid command... for every process. -ww defeats column truncation so long
# ssh command lines keep their destination. -A/-o/-ww are common to BSD ps
# (macOS) and procps (Linux).
ps -A -ww -o pid=,ppid=,command= 2>/dev/null | awk -v root="$root" '
  {
    pid = $1; ppid = $2;
    cmd = $0;
    sub(/^[ \t]*[0-9]+[ \t]+[0-9]+[ \t]+/, "", cmd);
    CMD[pid] = cmd;
    PAR[pid] = ppid;
  }
  END {
    root += 0;
    bestdepth = -1; best = "";

    # Among ssh processes, keep the one closest to the pane shell.
    for (p in CMD) {
      split(CMD[p], tok, /[ \t]+/);
      n = split(tok[1], seg, "/");        # basename of argv[0]
      if (seg[n] != "ssh") continue;

      cur = p; depth = 0; ok = 0;
      while (cur != "" && cur + 0 > 0 && depth < 128) {
        if (cur + 0 == root) { ok = 1; break; }
        cur = PAR[cur]; depth++;
      }
      if (ok && (bestdepth < 0 || depth < bestdepth)) {
        bestdepth = depth; best = CMD[p];
      }
    }

    if (best == "") { printf "[ssh]"; exit; }

    # Destination = first non-option token, skipping flags and their arguments.
    m = split(best, a, /[ \t]+/);
    takesarg = "bcDEeFIiJLlmOopQRSWw";   # ssh flags that consume an argument
    dest = "";
    i = 2;                                # a[1] == ssh
    while (i <= m) {
      t = a[i];
      if (t == "--") { dest = a[i + 1]; break; }
      if (substr(t, 1, 1) == "-") {
        rest = substr(t, 2);
        for (j = 1; j <= length(rest); j++) {
          if (index(takesarg, substr(rest, j, 1)) > 0) {
            if (j == length(rest)) i++;   # flag arg is the next token
            break;                        # else arg is bundled inline
          }
        }
        i++;
        continue;
      }
      dest = t; break;                    # first bare token is the destination
    }

    gsub(/#/, "##", dest);                # # is the tmux format escape
    if (dest == "") printf "[ssh]"; else printf "[ssh] %s", dest;
  }
'
