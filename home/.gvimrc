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

" Mappings

  " Switch to left/right pane
  nnoremap <silent> <D-[> <C-w>h
  nnoremap <silent> <D-]> <C-w>l

  " Comment
  nmap <silent> <D-/> <plug>NERDCommenterToggle
  xmap <silent> <D-/> <plug>NERDCommenterToggle

  " Split vertically (tmux-ish)
  nnoremap <silent> <D-d> <C-w>v

  " Split horizontally (tmux-ish)
  nnoremap <silent> <D-D> <C-w>s

  " Search
  macmenu Edit.Find.Find\.\.\. key=<nop>
  map <silent> <D-f> /

  " Fuzzy file explorer
  macmenu File.Open\.\.\. key=<nop>
  nnoremap <silent> <D-o> :CtrlP<CR>

  " Quit
  " <D-q> by default

  " Reload file
  nnoremap <silent> <D-r>      :nohl<CR>:redraw<CR>:checktime<CR><C-l>
  xnoremap <silent> <D-r> <C-c>:nohl<CR>:redraw<CR>:checktime<CR><C-l>gv

  " Save current buffer
  " <D-s> by default

  " New tab
  " <D-t> by default

  " Quit current buffer
  " <D-w> by default

  " Cancel
  " <D-z> by default

  " Repeat
  " <D-Z> by default
