au BufRead,BufNewFile *.ml,*.mli set ft=omlet
" setf omlet would result in having omlet not loaded cause system's 
" filetype.vim defines ocaml.vim for .ml files.
" This is quite ugly, but we have to do this until ocaml.vim becomes omlet...
