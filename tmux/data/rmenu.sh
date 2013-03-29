#!/bin/sh

ip="$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)"

uptime_day=0
if uptime | grep day >/dev/null 2>&1 ; then
  uptime_day=$(uptime | sed 's#.\+ up \([0-9]\+\) day.\+#\1#')
fi

if [ "$(uname -s)" = 'Darwin' ] ; then
  OS='MacOS X'
elif [ "$(uname -s)" = 'Linux' ] ; then
  OS="$(uname -o)"
else
  OS='Unkown OS'
fi

echo "[$(whoami)@$(hostname)] [$ip] [$OS] [${uptime_day}d]"

exit 0
