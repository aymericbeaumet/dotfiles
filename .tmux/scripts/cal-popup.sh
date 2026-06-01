#!/usr/bin/env bash
# 3-month calendar (Monday-first via -s GB) with today highlighted.
# Run directly in tmux popup TTY so ncal emits reverse-video ANSI for -H.

ncal -3 -s GB -H "$(date +%Y-%m-%d)"
echo
read -n1 -s -r
