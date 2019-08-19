#!/usr/bin/env bash

PATH=/usr/local/bin:$PATH

appName=$1
appExecutable=${2:-$1}

window=$(yabai -m query --windows | jq "[.[] | select(.app==\"$appName\")][0]")

if [ "$window" != 'null' ]; then
  yabai -m space --focus "$(echo "$window" | jq '.space')"
  yabai -m window --focus "$(echo "$window" | jq '.id')"
else
  open -a "$appExecutable"
fi
