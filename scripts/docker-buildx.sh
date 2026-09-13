#!/usr/bin/env sh
set -eu
exec mise exec -- docker-cli-plugin-docker-buildx "$@"
