#!/bin/sh
# This script will be sourced during installation

ABSPATH=$(cd "$(dirname "$0")"; pwd)

echo 'Installing vim bundles'

vim \
--cmd "let &rtp .= ',' . '$ABSPATH/vim/bundle/vundle'" \
--cmd "let g:vundle_install_dir = '$ABSPATH/vim/bundle'" \
-u "$ABSPATH/vimrc" \
+BundleInstall +qall
