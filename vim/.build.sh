#!/bin/sh
# This script will be sourced during installation

ABSPATH=$(cd "$(dirname "$0")"; pwd)

echo 'Installing Vim bundles via NeoBundle'

vim \
--cmd "let &rtp .= ',' . '$ABSPATH/vim/bundle/neobundle.vim'" \
--cmd "let g:bundle_dir = '$ABSPATH/vim/bundle'" \
-u "$ABSPATH/vimrc" \
+NeoBundleInstall +qall
