#!/bin/sh

battery_level="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
date="$(date +'%a %d %b %H:%M')"

echo "♥ $battery_level% | $date"
