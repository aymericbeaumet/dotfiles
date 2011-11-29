#!/bin/zsh

uptime_day=$(uptime | sed 's#.\+ up \([0-9]\+\) day.\+#\1#')

if [ $uptime_day -gt 1 ] ; then
	uptime_day="$uptime_day days"
else
	uptime_day="$uptime_day day"
fi

echo "[up $uptime_day] [$(date '+%d.%m.%Y %H:%M')]"
