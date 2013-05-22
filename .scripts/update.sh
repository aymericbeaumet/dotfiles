#!/bin/bash

set -e

# cd to the project root directory
cd "$(dirname "$0")/.."

# Update repo
git pull origin master

# Update submodules (init them if needed)
git submodule update --init

exit 0
