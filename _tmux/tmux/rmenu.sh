#!/bin/sh

os='unknown_OS'
arch='unknown_arch'
if which 'uname' >/dev/null 2>&1 ; then
  os=`uname -s`
  if [ `uname -s` = 'Linux' ] ; then
    os=`uname -o`
  fi

  arch=`uname -m`
fi

uptime_day='unknown_uptime'
if which 'uptime' >/dev/null 2>&1 ; then
  uptime_cache=`uptime`
  if echo "$uptime_cache" | grep day >/dev/null 2>&1 ; then
    uptime_day=`echo $uptime_cache | awk '{print $3;}'`
  else
    uptime_day='< 1 day'
  fi
fi

echo "[$os $arch] [$uptime_day]"

exit 0
