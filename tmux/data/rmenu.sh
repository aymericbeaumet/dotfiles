#!/bin/sh

uptime_day=0
if uptime | grep day >/dev/null 2>&1 ; then
  uptime_day=$(uptime | sed 's#.\+ up \([0-9]\+\) day.\+#\1#')
fi

echo "[$uptime_day] [$(date '+%d.%m.%Y %H:%M')]"

exit 0
