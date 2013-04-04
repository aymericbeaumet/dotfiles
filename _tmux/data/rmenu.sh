#!/bin/sh

user='unknown_user'
if which 'whoami' >/dev/null 2>&1 ; then
  user="$(whoami)"
fi

host='unknown_host'
if which 'host' >/dev/null 2>&1 ; then
  host="$(hostname)"
fi

ipv4='unknown_ip'
if which 'ip' >/dev/null 2>&1 ; then
  ipv4="$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)"
fi

uptime_day='unknown_uptime'
if which 'uptime' >/dev/null 2>&1 && uptime | grep day >/dev/null 2>&1 ; then
  uptime_day=$(uptime | sed 's#.\+ up \([0-9]\+ days*\).\+#\1#')
fi

os='unknown_OS'
arch='unknown_arch'
if which 'uname' >/dev/null 2>&1 ; then
  if [ "$(uname -s)" = 'Linux' ] ; then
    os="$(uname -o)"
  elif [ "$(uname -s)" = 'Darwin' ] ; then
    os='Mac OS'
  fi

  arch="$(uname -m)"
fi

echo "[$user@$host] [$ipv4] [$os $arch] [$uptime_day]"

exit 0
