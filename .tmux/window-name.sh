#!/bin/sh
cd "$1" 2>/dev/null || { basename "$1"; exit 0; }
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || { basename "$1"; exit 0; }
basename "$toplevel"
