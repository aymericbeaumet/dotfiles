#!/usr/bin/env bash
# Auto-open the "~All" query feed so newsboat lands on a flat, newest-first
# list of every article instead of the feed list.
( sleep 0.4 && tmux send-keys Enter ) &
exec newsboat
