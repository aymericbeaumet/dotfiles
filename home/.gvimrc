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

" Mappings (matches the one in ~/.vimrc, but with Command instead of <Leader>)
" `:e $VIMRUNTIME/menu.vim`

  " Switch to left/right pane
  nmap <silent> <D-[> <Leader>[
  nmap <silent> <D-]> <Leader>]

  " Comment
  nmap <silent> <D-/> <Leader>/
  xmap <silent> <D-/> <Leader>/

  " Split vertically (tmux-ish)
  nmap <silent> <D-d> <Leader>d

  " Split horizontally (tmux-ish)
  nmap <silent> <D-D> <Leader><S-d>

  " Search
  macmenu Edit.Find.Find\.\.\. key=<nop>
  map <silent> <D-f> <Leader>f

  " Fuzzy file explorer
  macmenu File.Open\.\.\. key=<nop>
  nmap <silent> <D-o> <Leader>o

  " Quit
  " <D-q> by default, cannot be overriden

  " Save current buffer
  macmenu File.Save key=<nop>
  nmap <silent> <D-s> <Leader>s

  " New tab
  macmenu File.New\ Tab key=<nop>
  nmap <silent> <D-t> <Leader>t

  " Quit current buffer
  macmenu File.Close key=<nop>
  nmap <silent> <D-w> <Leader>w

  " Undo
  macmenu Edit.Undo key=<nop>
  nmap <silent> <D-z> <Leader>z

  " Redo
  macmenu Edit.Redo key=<nop>
  nmap <silent> <D-Z> <Leader><S-z>
