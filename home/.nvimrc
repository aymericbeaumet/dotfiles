" Do not load vimrc in a sandbox
let g:localvimrc_sandbox=0

" Define python path
let g:python_host_prog = '/usr/local/bin/python2'
let g:python3_host_prog = '/usr/local/bin/python3'

" Load my .vimrc
execute 'source ' . resolve(expand('~/.vimrc'))
