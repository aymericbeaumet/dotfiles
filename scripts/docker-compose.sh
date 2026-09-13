#!/usr/bin/env sh
set -eu
exec mise exec -- docker-compose "$@"
