" Set the font
silent! set guifont=Monaco:h12
silent! set guifont=Inconsolata\ for\ Powerline:h14
silent! set guifont=Inconsolata:h14

" Disable all the superfluous GUI stuff
set guioptions=
set guicursor=

" Use console dialog instead of popup
set guioptions+=c

" use native tabs
set guioptions+=e

" Remove annoying cursor blinking...
set guicursor+=a:blinkon0

" Set the cursor as an underscore
set guicursor+=a:hor8

" easy navigation between tabs
nnoremap <silent> <C-S-Tab> gT
nnoremap <silent> <C-Tab> gt
