" Author: Aymeric Beaumet <aymeric@beaumet.me>
" Github: @aymericbeaumet/dotfiles

" Skip initialization for vim-tiny or vim-small
if !1 | finish | endif

" Disable Vi compatibility
if &compatible
  set nocompatible
endif

" Delete existing autocommands
au!

" {{{ Configuration

" Remap leader key to space (need to be done before any other mapping)
let mapleader = ' '

let b:tmp_directory = expand('~/.vim/tmp')

let b:easyalign = {
\   'mappings': {
\     'align': '<Enter>',
\   },
\ }

let b:narrowregion = {
\   'mappings': {
\     'narrow': '<Leader>nr',
\   },
\ }

let b:syntastic = {
\   'linters': {
\     'javascript': ['jshint'],
\   },
\   'mappings': {
\     'check': '<Leader>l',
\   },
\ }

let b:unite = {
\   'mappings': {
\     'buffers':         '<Leader>b',
\     'files':          '<Leader>f',
\     'grep':           '<Leader>g',
\     'grep_in_buffer': '<Leader>/',
\     'history_yank':   '<Leader>y',
\   },
\ }

let b:vim_easymotion = {
\   'mappings': {
\     'prefix': '<Leader>e',
\   },
\ }

let b:vim_expand_region = {
\   'mappings': {
\     'expand': 'v',
\   },
\ }

let b:winresizer = {
\   'mappings': {
\     'start_key': '<C-W><C-W>',
\   },
\ }

" }}}

" {{{ Plugins

" Start NeoBundle initialization

let g:bundle_dir = resolve(expand('~/.vim/bundle'))

if has('vim_starting')
  let &rtp .= ',' . g:bundle_dir . '/neobundle.vim/'
endif

call neobundle#begin(g:bundle_dir)

" Load plugins (if possible, use the NeoBundle cache)

if neobundle#load_cache()

  " Bundles dependencies

  NeoBundleLazy 'Shougo/vimproc.vim', {
  \   'build' : {
  \     'mac' : 'make -f make_mac.mak',
  \   },
  \ }

  NeoBundleLazy 'Shougo/neomru.vim'

  " NeoBundle

  NeoBundleFetch 'Shougo/neobundle.vim', {
  \   'depends': ['Shougo/vimproc.vim'],
  \   'vim_version': '7.2.051',
  \ }

  " CSS

  NeoBundleLazy 'JulesWang/css.vim', {
  \   'autoload': {
  \     'filetypes': ['css'],
  \   },
  \ }

  " Docker

  NeoBundleLazy 'ekalinin/Dockerfile.vim', {
  \   'autoload': {
  \     'filetypes': ['Dockerfile'],
  \   },
  \ }

  " Git

  NeoBundle 'airblade/vim-gitgutter', {
  \   'disabled': !executable('git'),
  \ }

  NeoBundleLazy 'tpope/vim-git', {
  \   'disabled': !executable('git'),
  \   'autoload': {
  \     'filetypes': ['git', 'gitcommit', 'gitconfig', 'gitrebase', 'gitsendemail'],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-fugitive', {
  \   'disabled': !executable('git'),
  \   'autoload': {
  \     'commands': ['Git', 'Gcd', 'Glcd', 'Gstatus', 'Gcommit', 'Gmerge', 'Gpull', 'Gpush', 'Gfetch', 'Ggrep', 'Glgrep', 'Glog', 'Gllog', 'Gedit', 'Gsplit', 'Gvsplit', 'Gtabedit', 'Gpedit', 'Gsplit', 'Gvsplit', 'Gtabedit', 'Gpedit', 'Gread', 'Gwrite', 'Gwq', 'Gdiff', 'Gsdiff', 'Gvdiff', 'Gmove', 'Gremove', 'Gblame', 'Gbrowse'],
  \   },
  \   'augroup': 'fugitive',
  \ }

  " HTML

  NeoBundleLazy 'othree/html5.vim', {
  \   'autoload': {
  \     'filetypes': ['html'],
  \   },
  \ }

  " Interface

  " the plugins having an integration in vim-airline cannot be lazy loaded
  " (hence the explicit dependencies to force their loading before vim-airline)
  NeoBundle 'bling/vim-airline', {
  \   'depends': ['tpote/vim-fugitive', 'airblade/vim-gitgutter', 'scrooloose/syntastic', 'Shougo/unite.vim', 'chrisbra/NrrwRgn'],
  \   'vim_version': '7.2',
  \ }

  NeoBundleLazy 'IndexedSearch', {
  \   'autoload': {
  \     'mappings': [
  \       ['n'] + ['/', '?', 'n', 'N', '*', '#'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'jimsei/winresizer', {
  \   'autoload': {
  \     'mappings': [
  \       ['n'] + values(b:winresizer.mappings),
  \     ],
  \   },
  \ }

  " Jade

  NeoBundleLazy 'digitaltoad/vim-jade', {
  \   'autoload': {
  \     'filetypes': ['jade'],
  \   },
  \ }

  " Javascript

  NeoBundleLazy 'pangloss/vim-javascript', {
  \   'autoload': {
  \     'filetypes': ['javascript', 'html'],
  \   },
  \ }

  NeoBundleLazy 'jelera/vim-javascript-syntax', {
  \   'autoload': {
  \     'filetypes': ['javascript'],
  \   },
  \ }

  NeoBundleLazy 'marijnh/tern_for_vim', {
  \   'build': {
  \     'mac': 'npm install',
  \   },
  \   'autoload': {
  \     'filetypes': ['javascript'],
  \   },
  \ }

  NeoBundleLazy 'myhere/vim-nodejs-complete', {
  \   'autoload': {
  \     'filetypes': ['javascript'],
  \   },
  \ }

  " JSON

  NeoBundleLazy 'elzr/vim-json', {
  \   'autoload': {
  \     'filetypes': ['json'],
  \   },
  \ }

  " Markdown

  NeoBundleLazy 'tpope/vim-markdown', {
  \   'autoload': {
  \     'filetypes': ['markdown'],
  \   },
  \ }

  " Motion

  NeoBundleLazy 'Lokaltog/vim-easymotion', {
  \   'autoload': {
  \     'mappings': [
  \       ['nvo'] + values(b:vim_easymotion.mappings),
  \     ],
  \   },
  \ }

  NeoBundleLazy 'matchit.zip', {
  \   'autoload': {
  \     'mappings': [
  \       ['nv'] + ['%', 'g%'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'terryma/vim-expand-region', {
  \   'autoload': {
  \     'mappings': [
  \       ['v'] + values(b:vim_expand_region.mappings),
  \     ],
  \   },
  \ }

  NeoBundleLazy 'thinca/vim-visualstar', {
  \   'autoload': {
  \     'mappings': [
  \       ['no', '*', '#', 'g*', 'g#'],
  \       ['v', '*', '<kMultiply>', '<S-LeftMouse>', '#', 'g*', 'g<kMultiply>', 'g<S-LeftMouse>', 'g#'],
  \     ],
  \   },
  \ }

  " Nginx

  NeoBundleLazy 'nginx.vim', {
  \   'autoload': {
  \     'filetypes': ['nginx'],
  \   },
  \ }

  " Stylus

  NeoBundleLazy 'wavded/vim-stylus', {
  \   'autoload': {
  \     'filetypes': ['stylus'],
  \   },
  \ }

  " Theme

  NeoBundle 'wombat256.vim'

  " Workflow

  NeoBundle 'airblade/vim-rooter'

  NeoBundleLazy 'chrisbra/NrrwRgn', {
  \   'autoload': {
  \     'commands': ['NR', 'NarrowRegion', 'NW', 'NarrowWindow', 'WidenRegion', 'NRV', 'NUD', 'NRPrepare', 'NRP', 'NRMulti', 'NRM', 'NRSyncOnWrite', 'NRS', 'NRNoSyncOnWrite', 'NRN', 'NRL'],
  \     'mappings': [
  \       ['nv'] + values(b:narrowregion.mappings),
  \     ],
  \   },
  \ }

  NeoBundleLazy 'editorconfig/editorconfig-vim', {
  \   'autoload': {
  \     'insert': 1,
  \   },
  \ }

  NeoBundleLazy 'junegunn/vim-easy-align', {
  \   'autoload': {
  \     'commands': ['EasyAlign', 'LiveEasyAlign'],
  \     'mappings': [
  \       ['v', b:easyalign.mappings.align],
  \     ],
  \   },
  \ }

  NeoBundle 'ntpeters/vim-better-whitespace'

  NeoBundleLazy 'scrooloose/nerdcommenter', {
  \   'vim_version': '7',
  \   'autoload': {
  \     'commands': ['NERDComComment', 'NERDComNestedComment', 'NERDComToggleComment', 'NERDComMinimalComment', 'NERDComInvertComment', 'NERDComSexyComment', 'NERDComYankComment', 'NERDComEOLComment', 'NERDComAppendComment', 'NERDComInsertComment', 'NERDComAltDelim', 'NERDComAlignedComment', 'NERDComUncommentLine'],
  \     'mappings': [
  \       ['nv'] + ['<Leader>cc', '<Leader>cn', '<Leader>c', '<Leader>cm', '<Leader>ci', '<Leader>cs', '<Leader>cy', '<Leader>c$', '<Leader>cA', '<Leader>ca', '<Leader>cl', '<Leader>cb', '<Leader>cu'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'scrooloose/syntastic', {
  \   'build': {
  \     'mac': 'npm install -g ' . join(b:syntastic.linters.javascript, ' '),
  \   },
  \   'vim_version': '7',
  \   'disabled': !has('autocmd') || !has('eval') || !has('file_in_path') || !has('modify_fname') || !has('quickfix') || !has('reltime') || !has('user_commands'),
  \   'autoload': {
  \     'filetypes': keys(b:syntastic.linters),
  \     'commands': ['Errors', 'SyntasticToggleMode', 'SyntasticCheck', 'SyntasticInfo', 'SyntasticReset', 'SyntasticSetLoclist'],
  \     'mappings': [
  \       ['n'] + values(b:syntastic.mappings),
  \     ],
  \   },
  \ }

  NeoBundleLazy 'Shougo/unite.vim', {
  \   'depends': ['Shougo/vimproc.vim', 'Shougo/neomru.vim'],
  \   'autoload': {
  \     'commands': ['Unite', 'UniteWithCurrentDir', 'UniteWithBufferDir', 'UniteWithProjectDir', 'UniteWithInput', 'UniteWithInputDirectory', 'UniteWithCursorWord', 'UniteResume', 'UniteClose', 'UniteNext', 'UnitePrevious', 'UniteFirst', 'UniteLast', 'UniteBookmarkAdd'],
  \     'mappings': [
  \       ['n'] + values(b:unite.mappings),
  \     ],
  \   },
  \ }

  NeoBundleLazy 'terryma/vim-multiple-cursors', {
  \   'autoload': {
  \     'commands': ['MultipleCursorsFind'],
  \     'mappings': [
  \       ['n'] + ['<C-n>', '<C-p>', '<C-x>']
  \     ],
  \   },
  \ }

  " This plugin cannot be lazily loaded
  " See: https://github.com/SirVer/ultisnips/issues/280
  NeoBundle 'SirVer/ultisnips'

  NeoBundleLazy 'tpope/vim-abolish', {
  \   'autoload': {
  \     'commands': ['Abolish', 'Subvert', 'S'],
  \     'mappings': [
  \       ['n'] + ['cr'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-endwise', {
  \   'autoload': {
  \     'filetypes': ['lua', 'elixir', 'ruby', 'crystal', 'sh', 'zsh', 'vb', 'vbnet', 'aspvbs', 'vim', 'c', 'cpp', 'xdefaults', 'objc', 'matlab'],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-eunuch', {
  \   'autoload': {
  \     'commands': ['Remove', 'Unlink', 'Move', 'Rename', 'Chmod', 'Mkdir', 'Find', 'Locate', 'SudoEdit', 'SudoWrite', 'Wall', 'W'],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-repeat', {
  \   'autoload': {
  \     'mappings': [
  \       ['n'] + ['.', 'u', 'U', '<C-R>'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-speeddating', {
  \   'autoload': {
  \     'commands': ['SpeedDatingFormat'],
  \     'mappings': [
  \       ['nv'] + ['<C-A>', '<C-X>'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-surround', {
  \   'autoload': {
  \     'mappings': [
  \       ['n'] + ['ds', 'cs', 'cS', 'ys', 'yS', 'yss', 'ySs', 'ySS'],
  \       ['x'] + ['S', 'gS'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'tpope/vim-unimpaired', {
  \   'autoload': {
  \     'mappings': [
  \       ['n'] + ['[a', ']a', '[A', ']A', '[b', ']b', '[B', ']B', '[l', ']l', '[L', ']L', '[<C-L>', ']<C-L>', '[q', ']q', '[Q', ']Q', '[<C-Q>', ']<C-Q>', '[t', ']t', '[T', ']T', '[f', ']f', '[n', ']n', '[<Space>', ']<Space>', '[e', ']e', '[ob', ']ob', 'cob', '[oc', ']oc', 'coc', '[od', ']od', 'cod', '[oh', ']oh', 'coh', '[oi', ']oi', 'coi', '[ol', ']ol', 'col', '[on', ']on', 'con', '[or', ']or', 'cor', '[os', ']os', 'cos', '[ou', ']ou', 'cou', '[ov', ']ov', 'cov', '[ow', ']ow', 'cow', '[ox', ']ox', 'cox', '>p', '>P', '<p', '<P', '=p', '=P', ']p', '[p', 'yo', 'yO', '[x', '[xx', ']x', ']xx', '[u', '[uu', ']u', ']uu', '[y', '[yy', ']y', ']yy'],
  \       ['v'] + ['[x', ']x', '[u', ']u', '[y', ']y'],
  \     ],
  \   },
  \ }

  NeoBundleLazy 'Valloric/YouCompleteMe', {
  \   'install_process_timeout': 3600,
  \   'build': {
  \     'mac': './install.sh --clang-completer',
  \   },
  \   'vim_version': '7.3.584',
  \   'disabled': !has('python'),
  \   'autoload': {
  \     'filetypes': ['javascript'],
  \   },
  \   'augroup': 'youcompletemeStart',
  \ }

  NeoBundleSaveCache

endif

" Setup plugins

let bundle = neobundle#get('NrrwRgn')
function! bundle.hooks.on_source(bundle)
  let g:nrrw_rgn_nohl = 1 " disable highlighting
  let g:nrrw_rgn_update_orig_win = 1 " update the cursor in the main buffer
endfunction
function! bundle.hooks.on_post_source(bundle)
  map <Nop> <Plug>NrrwrgnDo
  execute 'nnoremap <silent> ' . b:narrowregion.mappings.narrow . ' :NarrowRegion<CR>'
  execute 'vnoremap <silent> ' . b:narrowregion.mappings.narrow . ' :NarrowRegion<CR>'
endfunction

let bundle = neobundle#get('syntastic')
function! bundle.hooks.on_source(bundle)
  let g:syntastic_check_on_open = 1
  let g:syntastic_always_populate_loc_list = 1
  let g:syntastic_auto_loc_list = 2
  let g:syntastic_javascript_checkers = b:syntastic.linters.javascript
  let g:syntastic_mode_map = {
  \   'mode': 'passive',
  \   'active_filetypes': keys(b:syntastic.linters),
  \   'passive_filetypes': [],
  \ }
endfunction
function! bundle.hooks.on_post_source(bundle)
  execute 'nnoremap <silent> ' . b:syntastic.mappings.check . ' :SyntasticCheck<CR>'
endfunction

let bundle = neobundle#get('ultisnips')
function! bundle.hooks.on_source(bundle)
  let g:UltiSnipsSnippetDirectories = ['snippet']
  let g:UltiSnipsExpandTrigger = '<C-J>'
  let g:UltiSnipsJumpForwardTrigger = '<C-J>'
  let g:UltiSnipsJumpBackwardTrigger = '<C-K>'
endfunction

let bundle = neobundle#get('unite.vim')
function! bundle.hooks.on_source(bundle)
  let g:unite_data_directory = expand(b:tmp_directory . '/unite') " change the temporary directory
  let g:unite_source_history_yank_enable = 1
  let g:unite_enable_start_insert = 1
  let g:unite_enable_short_source_names = 1
  let g:unite_split_rule = 'botright'
  let g:unite_update_time = 300
  let g:unite_source_file_mru_limit = 100
  let g:unite_prompt = '➜ '
  let g:unite_source_session_enable_auto_save = 1
  call unite#custom_source('file_rec,file_rec/async,file_mru,file,buffer,grep', 'ignore_pattern', join([
  \   '\.git/',
  \   'node_modules/',
  \   'bower_components/',
  \ ], '\|'))
endfunction
function! bundle.hooks.on_post_source(bundle)
  call unite#filters#sorter_default#use(['sorter_rank'])
  call unite#filters#matcher_default#use(['matcher_fuzzy'])
  nnoremap [unite] <Nop>
  execute 'nnoremap <silent> ' . b:unite.mappings.buffers        . ' :<C-U>Unite -buffer-name=buffers -quick-match buffer<CR>'
  execute 'nnoremap <silent> ' . b:unite.mappings.files          . ' :<C-U>Unite -buffer-name=files -auto-resize file file_rec/async file_mru<CR>'
  execute 'nnoremap <silent> ' . b:unite.mappings.grep           . ' :<C-U>Unite -buffer-name=grep grep:.<CR>'
  execute 'nnoremap <silent> ' . b:unite.mappings.grep_in_buffer . ' :<C-U>Unite -buffer-name=grep_in_buffer line<CR>'
  execute 'nnoremap <silent> ' . b:unite.mappings.history_yank   . ' :<C-U>Unite -buffer-name=history_yanks history/yank<CR>'
endfunction

let bundle = neobundle#get('vim-airline')
function! bundle.hooks.on_source(bundle)
  let g:airline_theme = 'badwolf' " specify theme
  let g:airline_exclude_preview = 1 " remove airline from preview window
  let g:airline_powerline_fonts = 0 " explicitly disable powerline fonts support
  let g:airline_left_sep = '' " remove left separator
  let g:airline_right_sep = '' " remove right separator
  let g:airline_section_z = '%p%% L%l:C%c' " rearrange percentage/col/line section
  let g:airline#extensions#tabline#enabled = 1 " display buffer line
endfunction
function! bundle.hooks.on_post_source(bundle)
  set noshowmode " hide the duplicate mode in bottom status bar
endfunction

let bundle = neobundle#get('vim-better-whitespace')
function! bundle.hooks.on_post_source(bundle)
  nnoremap <silent> <Leader>s :StripWhitespace<CR>
endfunction

let bundle = neobundle#get('vim-easy-align')
function! bundle.hooks.on_source(bundle)
  execute 'vmap <silent> ' . b:easyalign.mappings.align . ' <Plug>(EasyAlign)'
endfunction

let bundle = neobundle#get('vim-easymotion')
function! bundle.hooks.on_source(bundle)
  let g:EasyMotion_keys = 'LPUFYW;QNTESIROA' " Colemak toprow/homerow
  let g:EasyMotion_smartcase = 1 " like Vim
  let g:EasyMotion_use_upper = 1 " recognize both upper and lowercase keys
  let g:EasyMotion_use_smartsign_us = 1 " ! and 1 are treated as the same
  let g:EasyMotion_off_screen_search = 0 " do not search outside of screen
endfunction
function! bundle.hooks.on_post_source(bundle)
  silent! unmap <Leader><Leader>
  execute 'nmap <silent> ' . b:vim_easymotion.mappings.prefix . ' <Plug>(easymotion-prefix)'
  execute 'vmap <silent> ' . b:vim_easymotion.mappings.prefix . ' <Plug>(easymotion-prefix)'
  execute 'omap <silent> ' . b:vim_easymotion.mappings.prefix . ' <Plug>(easymotion-prefix)'
endfunction

let bundle = neobundle#get('vim-expand-region')
function! bundle.hooks.on_post_source(bundle)
  silent! unmap +
  silent! unmap _
  execute 'vmap <silent> ' . b:vim_expand_region.mappings.expand . ' <Plug>(expand_region_expand)'
endfunction

let bundle = neobundle#get('vim-gitgutter')
function! bundle.hooks.on_source(bundle)
  let g:gitgutter_map_keys = 0
endfunction

let bundle = neobundle#get('vim-javascript')
function! bundle.hooks.on_source(bundle)
  let javascript_enable_domhtmlcss = 1 " enable HTML/CSS highlighting
endfunction

let bundle = neobundle#get('vim-nodejs-complete')
function! bundle.hooks.on_source(bundle)
  let g:nodejs_complete_config = { 'js_compl_fn': 'tern#Complete' }
endfunction

let bundle = neobundle#get('vim-surround')
function! bundle.hooks.on_source(bundle)
  let g:surround_no_insert_mappings = 1 " not insert mappings
  let g:surround_indent = 1 " reindent with `=` after surrounding
endfunction

let bundle = neobundle#get('vim-rooter')
function! bundle.hooks.on_source(bundle)
  let g:rooter_disable_map = 1 " do not map any bindings
  let g:rooter_silent_chdir = 1 " do not notify when changing directory
  let g:rooter_change_directory_for_non_project_files = 1 " chdir even when not in a project
  let g:rooter_use_lcd = 1 " change the cd on a per window basis
endfunction

let bundle = neobundle#get('winresizer')
function! bundle.hooks.on_source(bundle)
  let g:winresizer_start_key = b:winresizer.mappings.start_key
endfunction

let bundle = neobundle#get('wombat256.vim')
function! bundle.hooks.on_post_source(bundle)
  " enable theme
  silent! colorscheme wombat256mod
  " Change spell detection skin
  hi clear SpellBad
  hi clear SpellCap
  hi clear SpellLocal
  hi clear SpellRare
  hi SpellBad cterm=underline gui=underline
  hi SpellCap cterm=underline gui=underline
  hi SpellLocal cterm=underline gui=underline
  hi SpellRare cterm=underline gui=underline
  " Highlight color column
  set colorcolumn=+1 " relative to text-width
  hi ColorColumn ctermbg=0 guibg=black
endfunction

let bundle = neobundle#get('YouCompleteMe')
function! bundle.hooks.on_source(bundle)
  let g:ycm_complete_in_comments = 1
  let g:ycm_collect_identifiers_from_tags_files = 1
  let g:ycm_seed_identifiers_with_syntax = 1
  let g:ycm_key_list_select_completion = ['<C-N>', '<Down>']
  let g:ycm_key_list_previous_completion = ['<C-P>', '<Up>']
  let g:ycm_global_ycm_extra_conf = '~/.vim/.ycm_extra_conf.py'
endfunction
function! bundle.hooks.on_post_source(bundle)
  set completeopt=longest,menuone
endfunction

" End NeoBundle initialization

NeoBundleCheck

call neobundle#end()

" }}}

" {{{ Mappings

" up and down are more logical with g
nnoremap <silent> j gj
vnoremap <silent> j gj
nnoremap <silent> k gk
vnoremap <silent> k gk

" hide last search matches, refresh screen, re-read current buffer
" See: http://www.reddit.com/r/vim/comments/1vdrxg/space_is_a_big_key_what_do_you_map_it_to/ceri6yf
nnoremap <silent> <C-L>      :nohl<CR>:redraw<CR>:checktime<CR><C-L>
vnoremap <silent> <C-L> <C-C>:nohl<CR>:redraw<CR>:checktime<CR><C-L>gv

" copy from the cursor to the end of line using Y (matches D behavior)
nnoremap <silent> Y y$

" keep the cursor in place while joining lines (uses the `j` register)
nnoremap <silent> J mjJ`j

" disable annoying keys
noremap  <silent> <F1>  <Nop>
inoremap <silent> <F1>  <Nop>
nnoremap <silent> <C-C> <Nop>
noremap  <silent> <Del> <Nop>

" reselect visual block after indent
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" fix how ^E and ^Y behave in insert mode
inoremap <silent><expr> <C-e> pumvisible() ? "\<C-y>\<C-e>" : "\<C-e>"
inoremap <silent><expr> <C-y> pumvisible() ? "\<C-y>\<C-y>" : "\<C-y>"

" [b]uffer search
" <Leader>b

" [c] NerdCommenter prefix
" <Leader>c

" [d]elete the current buffer (lowercase saves it before / uppercase trashes the
" modifications)
nnoremap <silent> <Leader>d :w<CR>:bd<CR>
nnoremap <silent> <Leader>D :bd!<CR>

" [e]asymotion prefix
" <Leader>e

" [f]ile search
" <Leader>f

" [g]rep search
" <Leader>g

" [l]int file
" <Leader>l

" [n]arrow [r]egion
" <Leader>nr

" [r]eload the configuration
nnoremap <silent> <Leader>r :source ~/.vimrc<CR>

" [s]trip trailing whitespaces
" <Leader>s

" [t]ree (file explorer)
" <Leader>t

" [w]rite the current buffer
nnoremap <silent> <Leader>w :w<CR>
nnoremap <silent> <Leader>W :w!<CR>

" [y]ank history
" <Leader>y

" [q]uit the current buffer (uppercase trashes the modifications)
nnoremap <silent> <Leader>q :q<CR>
nnoremap <silent> <Leader>Q :q!<CR>

" [/] fuzzy search in the current buffer
" <Leader>/

" }}}

" {{{ Options

let g:netrw_dirhistmax = 0 " disable netrw

set autoindent           " auto-indentation
set autoread             " watch for file changes by other programs
set autowrite            " automatically save before :next and :make
set background=dark      " dark background
set backspace=2          " fix backspace (on some OS/term)
set encoding=utf-8       " ensure proper encoding
set expandtab            " replace tabs by spaces
set fileencodings=utf-8  " ensure proper encoding
set formatoptions=croqj  " format option stuff (see :help fo-table)
set gdefault             " default substitute g flag
set hidden               " when a tab is closed, do not delete the buffer
set history=1000         " increase history size
set ignorecase           " ignore case when searching
set incsearch            " show matches as soon as possible
set laststatus=2         " always display status line
set lazyredraw           " only redraw when needed
set modeline             " enable modelines for per file configuration
set modelines=3          " consider the first/last three lines
set nobackup             " disable backup files
set noerrorbells         " turn off error bells
set nofoldenable         " disable folding
set nostartofline        " leave my cursor position alone!
set noswapfile           " disable swap files
set scrolloff=8          " keep at least 8 lines after the cursor when scrolling
set shell=zsh            " shell for :sh
set shiftwidth=2         " n spaces when using <Tab>
set shortmess=aoOsI      " disable vim welcome message / enable shorter messages
set showcmd              " show (partial) command in the last line of the screen
set sidescrolloff=10     " (same as `scrolloff` about columns during side scrolling)
set smartcase            " smarter search
set smarttab             " insert `shiftwidth` spaces instead of tabs
set softtabstop=2        " n spaces when using <Tab>
set spell                " enable spell checking by default
set spellfile=~/.vim/spell/en.utf-8.add " additional spell file
set spelllang=en_us      " configure spell language
set t_Co=256             " 256 colors
set tabstop=2            " n spaces when using <Tab> (may be overriden for specific filetypes)
set textwidth=80         " 80 characters line
set timeoutlen=500       " time to wait when a part of a mapped sequence is typed
set ttimeoutlen=0        " instant insert mode exit using escape
set ttyfast              " we have a fast terminal
let &viminfo = &viminfo + ',n' . b:tmp_directory . '/info' " change viminfo file path
set virtualedit=block    " allow the cursor to go in to virtual places
set visualbell t_vb=     " turn off error bells
set wildignore+=*.o,*.so,*.a,*.dylib,*.pyc  " ignore compiled files
set wildignore+=*.zip,*.gz,*.xz,*.tar       " ignore compressed files
set wildignore+=.*.sw*,*~                   " ignore temporary files
set wildmenu             " better command line completion menu
set wildmode=full        "  `-> ensure better completion
set splitbelow           " slit below
set splitright           " split right

if has('mouse')          " enable mouse support
  set mouse=a
  if has('mouse_sgr') || v:version > 703 || v:version == 703 && has('patch632')
    set ttymouse=sgr
  else
    set ttymouse=xterm2
  endif
endif

if has('persistent_undo')
  set undofile           " enable undo files
  set undolevels=1000    " number of undo level
  set undoreload=10000   " number of lines to save for undo
  let &undodir = b:tmp_directory . '/undo//' " undo files directory
endif

au VimEnter * set relativenumber " relative line numbering by default
au InsertEnter * setl norelativenumber number " classic in insert mode
au InsertLeave * setl nonumber relativenumber " relative out of insert mode

set cursorline           " highlight cursor line
au VimEnter * hi CursorLine cterm=bold
au InsertEnter * setl nocursorline " do not highlight in insert mode
au InsertLeave * setl cursorline " highlight out of insert mode

au VimEnter * set hlsearch " highlight last search matches
au InsertEnter * setl nohlsearch " hide search highlighting in insert mode
au InsertLeave * setl hlsearch " ... and re-enable when leaving

" remember last position in file (line and column)
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line('$') | execute 'normal! g`"' | endif

" }}}

" Enable syntax
syntax enable

" Enable filetypes detection
filetype plugin indent on

" Call NeoBundle post source hooks again to support several consecutive `source
" ~/.vimrc`
call neobundle#call_hook('on_post_source')

" Avoid ~/.{vimrc,exrc} modification by autocmd, shell and write. It has to be
" at the end of the .vimrc
set secure
