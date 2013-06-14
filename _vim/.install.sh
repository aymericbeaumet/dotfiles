#!/bin/sh
# This script will be sourced during installation

echo 'Installing vim bundles'

vim +BundleInstall +qall
