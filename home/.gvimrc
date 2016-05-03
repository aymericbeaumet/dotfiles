" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles

" GUI

  " Set the font
  silent! set guifont=Monaco:h13 " fallback
  silent! set guifont=Hack:h13 " preferred

  " Disable superfluous GUI stuff
  set guicursor=
  set guioptions=

  " Use console dialog instead of popup
  set guioptions+=c

  " Disable cursor blinking
  set guicursor+=a:blinkon0

  " Set the cursor as an underscore
  set guicursor+=a:hor8

  " Make Command+W delete the current buffer
  macmenu File.Close key=<nop>
  nnoremap <silent> <D-w> :bdelete<CR>

  " Navigate between buffers with Command+{ and Command+}
  macmenu Window.Select\ Next\ Tab key=<nop>
  macmenu Window.Select\ Previous\ Tab key=<nop>
  nnoremap <silent> <D-{> :bprev<CR>
  nnoremap <silent> <D-}> :bnext<CR>
