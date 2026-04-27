#!/bin/sh
if ifconfig en0 2>/dev/null | grep -q 'status: active'; then
  printf '#[fg=colour178]wifi'
else
  printf '#[fg=red]wifi'
fi
