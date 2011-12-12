#!/bin/zsh

if uptime | grep day > /dev/null 2> /dev/null ; then
  uptime_day=$(uptime | sed 's#.\+ up \([0-9]\+\) day.\+#\1#')
else
  uptime_day=0
fi

date=$(date '+%d.%m.%Y %H:%M')

echo "[$uptime_day] [$date]"
