#!/bin/zsh

uptime_day=$(uptime | sed 's#.\+ up \([0-9]\+\) day.\+#\1d#')
date=$(date '+%d.%m.%Y %H:%M')

echo "[$uptime_day] [$date]"
