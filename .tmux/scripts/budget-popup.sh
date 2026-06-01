#!/usr/bin/env bash
# Last 7 days of Claude Code spend via ccusage.
# COLUMNS=200 prevents ccusage from wrapping the YYYY-MM-DD date column
# when the popup TTY is narrower than the full table.

since=$(date -v-6d +%Y-%m-%d)
today=$(date +%Y-%m-%d)
COLUMNS=200 ccusage claude daily --since "$since" --until "$today" | less -RS +G
