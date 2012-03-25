" Vim indent file
" Language:    OCaml
" Maintainer:  David Baelde <firstname.name@ens-lyon.org>
" URL:         http://ocaml.info/vim/indent/omlet.vim
" Last Change: 2005 Apr 08
" Changelog:
"         0.13 - Comments are now always aligned on the next block
"              - Corrected a bug related to comment un-skipping
"              - Added 'c', "=" and [|...|] handling. Sorry for the delay :)
"         0.12 - Added OCaml modeline support
"              - Prevented a few abusive autoindentation, when atoms begin
"                like keywords ("incr"...)
"              - Multiple comments are now aligned on the next real block
"              - New option omlet_middle_comment, still has pb with autoindent
"              - Corrected the parsing return value -- indentation of "and"
"              - Indentation code for ";" handles "bla ; bla ;\nbla" better
"              - Added "mod"
"         0.11 - Enhanced a lot the expression backward parsing, including
"                many infix operators, which are now well considered regarding
"                their binding power
"              - s:indent() was enhanced a lot

" omlet.vim -- a set of files for working on OCaml code with VIm
" Copyright (C) 2005 David Baelde
"
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 2 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software
" Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

" TODO cannot re-indent when || is typed at begining of line

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal expandtab
setlocal fo=croq
syntax enable
setlocal indentexpr=GetOMLetIndent(v:lnum)
setlocal indentkeys=0{,0},!^F,o,O,0=let\ ,0=and,0=in,0=end,0),0],0=\|],0=do,0=done,0=then,0=else,0=with,0\|,0=->,0=;;,0=module,0=struct,0=sig,0=class,0=object,0=val,0=method,0=initializer,0=inherit,0=open,0=include,0=exception,0=external,0=type,0=&&,0^,0*,0\,,0=::,0@,0+,0/,0-

" Get the modeline
let s:s = line2byte(line('.'))+col('.')-1
if search('^\s*(\*:o\?caml:')
  let s:modeline = getline(".")
else
  let s:modeline = ""
endif
if s:s > 0
  exe 'goto' s:s
endif

" P is a modeline param name, S a global variable name, V the default value
function! s:default(p,s,v)
  let m = matchstr(s:modeline,a:p.'\s*=\s*\d\+')
  if m != ""
    return matchstr(m,'\d\+')
  elseif exists(a:s)
    exe "return" a:s
  else
    return a:v
  endif
endfunction

let b:i = s:default("default","g:omlet_indent",2)
let b:i_struct = s:default("struct","g:omlet_indent_struct",b:i)
let b:i_match = s:default("match","g:omlet_indent_match",b:i)
let b:i_function = s:default("fun","g:omlet_indent_function",b:i)
let b:i_let = s:default("let","g:omlet_indent_let",b:i)
let b:mb = s:default("xxx","g:omlet_middle_comment",1)

if b:mb != 0
  let b:mb = 1
endif

if b:mb == 1
  setlocal comments=s1l:(*,mb:*,ex:*)
else
  setlocal comments=s1l:(*,ex:*)
endif

" Do not define our functions twice
if exists("*GetOMLetIndent")
  finish
endif
let b:did_indent = 1

" {{{ A few utils

function s:save()
  return line2byte(line('.'))+col('.')-1
endfunction

function s:restore(v)
  execute 'goto ' a:v
endfunction

" Same as searchpair() but skips comments and strings
function s:searchpair(beg,mid,end,flags)
  return searchpair(a:beg,a:mid,a:end,a:flags,'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
endfunction

" Same as search(_,'bW') but skips comments
function s:search(re)
  let p = s:save()
  while search('\*)\_s*\%#','bW')
    call searchpair('(\*','','\*)','bW')
  endwhile
  if search(a:re,'bW')
    return 1
  else
    call s:restore(p)
  endif
endfunction

" Goes back to the beginning of an "end", whatever its opening keyword is
let s:begend = '\%(\<begin\>\|\<object\>\|\<struct\>\|\<sig\>\)'
function OMLetBegendBackward()
  return s:searchpair(s:begend,'','\<end\>','bW')
endfunction

" }}}

" {{{ Jumping
" We separated expressions in three classes:
"  A: The applications
"  E: A + closure by infix operators which bind tighter than ";"
"        We ignore the aggregating "let" and the special "then" operator
"  Block: Full expressions, it's a mess...
" "then", "match", "patterns"...

" Goes to the beginning of the previous (exclusive) block.
" It is stopped by any non-trivial syntax.
" The block moves are really the heart of omlet!

let s:blockstop = '\(\%^\|(\|{\|\[\|\[|\|\<begin\>\|;\|,\|&&\|||\|\<try\>\|\<match\>\|\<with\>\||\|->\|\<when\>\|\<of\>\|\<fun\>\|\<function\>\|=\|\<let\>\|\<in\>\|\<for\>\|\<to\>\|\<do\>\|\<while\>\|\<if\>\|\<then\>\|\<else\>\|\<sig\>\|\<struct\>\|\<object\>\)\_s*\%#'

let s:binop_core = '\%(\<lor\>\|\<land\>\|\<lsr\>\|\<lsl\>\|\<asr\>\|\<asl\>\|\<mod\>\|,\|::\|@\|\^\|||\|&&\|\.\|<-\|:=\|+\|\*\|/\|-\)'
" Thanks to ".", floating point arith operators are included...
let s:binop = s:binop_core.'\_s*\%#'

function OMLetAtomBackward()
  let s = s:save()

  if search('\*)\_s*\%#','bW')
    call searchpair('(\*','','\*)','bW')
    return OMLetAtomBackward()

  elseif search(')\_s*\%#','bW')
    return s:searchpair('(','',')','bW')

  elseif search('\]\_s*\%#','bW')
    return s:searchpair('\[','','\]','bW')

  elseif search('}\_s*\%#','bW')
    return s:searchpair('{','','}','bW')

  elseif search("'\\_s*\\%#",'bW')
    while search("\\_.'",'bW')
      if synIDattr(synID(line("."), col("."), 0), "name") != "ocamlCharacter"
        call search("'")
        return 1
      endif
    endwhile
    throw "Couldn't find beginning of character"

  elseif search('"\_s*\%#','bW')
    while search('\_."','bW')
      if synIDattr(synID(line("."), col("."), 0), "name") != "ocamlString"
        call search('"')
        return 1
      endif
    endwhile
    throw "Couldn't find beginning of string"

  elseif search('\<done\>\_s*\%#','bW')
    call s:searchpair('\<do\>','','\<done\>','bW')
    return s:searchpair('\%(\<while\>\|\<for\>\)','','\<do\>','bW')

  elseif search('\<end\>\_s*\%#','bW')
    if synIDattr(synID(line("."), col("."), 0), "name") == "ocamlKeyword"
      call s:searchpair('\<begin\>','','\<end\>','bW')
      return 1
    else
      call s:restore(s)
    endif

  elseif search('\%(!\|`\|#\|\.\)\_s*\%#','bW')
    " Ignore some atom prefixes
    return OMLetAtomBackward()

  elseif search(s:binop,'bW') || search(s:blockstop,'bW')
    " Stop moving in front of those block delimiters
    call s:restore(s)
    return 0

  else
    " Otherwise, move backward, skipping a variable name or constant...
    return search('\<','bW')
  endif
endfunction

function OMLetABackward()
  if OMLetAtomBackward()
    while OMLetAtomBackward()
    endwhile
    return 1
  else
    return 0
  endif
endfunction

function OMLetEBackward()
  if OMLetABackward()
    call OMLetEBackward()
    return 1
  endif

  if s:search(s:binop)
    call OMLetEBackward()
    return 1
  endif

  let s = s:save()
  if search('=\_s*\%#','bW')
    if search('\%(\<let\>\|\<val\>\|\<method\>\|\<type\>\)[^=]\+\%#','bW')
      call s:restore(s)
      return 0
    else
      call OMLetEBackward()
      return 1
    endif
  endif
endfunction

" }}}

" {{{ Complex jumping
" We still have problems with "match", and "else",
" which have no closing keyword.

function OMLetMatchHeadBackward()
  if s:search('\<with\>\_s*\%#')
    call s:searchpair('\%(\<try\>\|\<match\>\)','','\<with\>','bW')
    return 1
  elseif s:search('\<fun\>\_s*\%#')
    return 1
  elseif s:search('\<function\>\_s*\%#')
    return 1
  elseif s:search('\<type\>\_[^=]\+=\_s*\%#')
    return 1
  else
    return 0
  endif
endfunction

function OMLetIfHeadBackward()
  if search('\<then\_s*\%#','bW')
    call s:searchpair('\<if\>','','\<then\>','bW')
  else
    throw "Indentation failed!"
  endif
endfunction

function OMLetBlockBackward(lf,gbg)
  if search('\<else\_s*\%#','bW')
    call OMLetBlockBackward('then',a:gbg)
    call OMLetIfHeadBackward()
    call OMLetBlockBackward(a:lf,a:gbg)
    return 1

  elseif OMLetEBackward()
    call OMLetBlockBackward(a:lf,a:gbg)
    while searchpair('(\*','','\*)')
      " Undo some abusive comment jumping...
      " Go to the real end of comment, then to the next meaningful point
      call search(')')
      call search('\S')
    endwhile
    return 1

  elseif a:lf == 'then'
    return 0

  elseif search('\<then\_s*\%#','bW')
    call s:searchpair('\<if\>','','\<then\>','bW')
    call OMLetBlockBackward(a:lf,a:gbg)
    return 1

  elseif a:lf == ';'
    return 0

  elseif search('\<in\>\_s*\%#','bW')
    call s:searchpair('\<let\>','','\<in\>','bW')
    call OMLetBlockBackward(a:lf, 0) " [let ... in] eats the garbage
    return 1

  elseif search(';\_s*\%#','bW')
    call OMLetBlockBackward(a:lf,1) " sequence is the garbage
    return 1

  elseif search('\<when\_s*\%#','bW')
    call OMLetBlockBackward(a:lf,0)
    return 1

  elseif search('\%(->\|\<of\>\)\_s*\%#','bW')
    call OMLetPatternBackward()
    call OMLetBlockBackward('match',0)
    if a:lf != 'match'
      call OMLetMatchHeadBackward()
      call OMLetBlockBackward(a:lf,0) " match has eaten the garbage
    endif
    return 1

  endif
  return 0
endfunction

function OMLetPatternBackward()
  call OMLetBlockBackward('',0)
  call search('|\_s*\%#','bW') " allow failure
endfunction

" }}}

" {{{ Indentation function
" The goal is to return a 'correct' indentation,
" assuming that the previous lines are well indented.

function s:indent(...)
  " The optionnal argument avoids ignoring leading "| "

  " If there's a hard delimiter like "{","(","[", its position is
  " used as the reference for the indentation
  let p = s:save()
  let l = line(".")
  if !search('\%#[{(\[]') && s:searchpair('[\[{(]','','[)}\]]','bW') && line(".") == l
    call search('\S')
    return col('.')-1
  else
    call s:restore(p)
  endif

  if a:0==0 && search('^\s*\%(|.*\%#\|\%#|\)','bW')
    " We consider leading "|" as whitespace
    call search('|')
    call search('\S')
    return col('.')-1
  endif

  return indent('.')
endfunction

function s:topindent(lnum)
  let l = a:lnum
  while l > 0
    if getline(l) =~ '\s*\%(\<struct\>\|\<sig\>\|\<object\>\)'
      return b:i_struct+indent(l)
    endif
    let l = l-1
  endwhile
  return 0
endfunction

function GetOMLetIndent(l)

  " Go to the first non-blank char on the line to be indented.
  exe a:l

  " {{{ Comments

  " Inside comments -- needs the comment to be closed!
  if synIDattr(synID(line("."), col("."), 0), "name") == 'ocamlComment'
    " TODO the first line inside the comment isn't autoindented correctly
    if searchpair('(\*','','\*)','bW')
      " We were strictly inside the comment, and we are now at its beginning
      " Let's jump to the last *
      call search('\*\_[^\*]')
      if b:mb == 0 && getline(a:l) !~ '^\s*\*)'
        return col('.')+1
      else
        return col('.')-1
      endif
    endif
    " No need to restore, there was no move
  endif

  " Comments with a blank line before them are indented as the next block
  if getline(a:l) =~ '^\s*(\*'
    let ok = 1
    while ok == 1
      call searchpair('(\*','','\*)')
      " TODO this would be better : /\%#\*)\_s*(/e
      if getline(line('.')+1) =~ '^\s*(\*'
        exe line('.')+1
      else
        let ok = 0
      endtry
    endwhile

    let new = nextnonblank(line('.')+1)
    if new == 0 || new == a:l
      return -1
    else
      return GetOMLetIndent(new)
    endif
  endif

  " }}}

  " {{{ Keyword alignments
  " How to indent a line starting with a keyword

  " Parenthesis-like closing

  if getline(a:l) =~ '^\s*\<end\>' && s:searchpair(s:begend,'','\<end\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*}'
    call s:searchpair('{','','}','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*)'
    call s:searchpair('(','',')','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*\]'
    call s:searchpair('\[','','\]','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*|\]'
    call s:searchpair('\[|','','|\]','bW')
    return s:indent()
  endif

  " WHILE and FOR

  if getline(a:l) =~ '^\s*\<done\>' && s:searchpair('\<do\>','','\<done\>','bW')
    call s:searchpair('\%(\<while\>\|\<for\>\)','','\<do\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*\<do\>' && s:searchpair('\<\(while\|for\)\>','','\<do\>','bW')
    return s:indent()
  endif

  " PATTERNS

  if getline(a:l) =~ '^\s*\<with\>' && s:searchpair('\%(\<try\>\|\<match\>\)','','\<with\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*->'
    call OMLetPatternBackward()
    if search('\%#|')
      return s:indent(1)+2
    else
      return s:indent()
    endif
  endif

  if getline(a:l) =~ '^\s*|'
    call OMLetBlockBackward('match',0)
    if s:search('|\_s*\%#')
      " We are stuck on a 0-ary constructor
      return s:indent(1)
    elseif s:search('\[\_s*\%#')
      " Polymorphic variant
      return col(".")-1
    elseif s:search('function\_s*\%#')
      return s:indent()+b:i_function
    else
      call OMLetMatchHeadBackward()
      return s:indent()+b:i_match
    endif
  endif

  " INFIX "&&", "||", "^", ...
  if getline(a:l) =~ '^\s*'.s:binop_core
    call OMLetEBackward()
    return s:indent()
  endif

  " IF/THEN/ELSE

  if getline(a:l) =~ '^\s*\<then\>' && s:searchpair('\<if\>','','\<then\>','bW')
    return s:indent()
  endif

  if getline(a:l) =~ '^\s*\<else\>'
    call OMLetBlockBackward('then',0)
    if s:search('\<then\_s*\%#')
      call s:searchpair('\<if\>','','\<then\>','bW')
    endif
    return s:indent()
  endif

  " ;; alone is indented as toplevel defs
  if getline(a:l) =~ '^\s*;;'
    if OMLetBegendBackward()
      return s:indent()+b:i_struct
    else
      return 0
    endif
  endif

  " { and [ may need to be reindented in type definitions, where they don't
  " really deserve the default +4 indentation
  " if getline(a:l) =~ '^\s*{'
  "   return s:indent(a:l-1)+2 " But that's weak !
  " endif

  " Easy toplevel definitions
  if getline(a:l) =~ '^\s*\%(\<open\>\|\<include\>\|\<struct\>\|\<object\>\|\<sig\>\|\<val\>\|\<module\>\|\<class\>\|\<type\>\|\<method\>\|\<initializer\>\|\<inherit\>\|\<exception\>\|\<external\>\)'
    if s:searchpair(s:begend,'','\<end\>','bW')
      return s:indent()+b:i_struct
    else
      return 0
    endif
  endif

  " The next three tests are for indenting toplevel let

  " let after a high-level end (not matching a begin)
  if getline(a:l) =~ '^\s*let\>' && s:search('\<end\>\_s*\%#') && synIDattr(synID(line('.'),col('.'),0),'name') != 'ocamlKeyword'
    call OMLetBegendBackward()
    return s:indent()
  else
    exe a:l
  endif

  " let at the beginning of a structure
  if getline(a:l) =~ '^\s*let\>' && s:search('\<struct\>\_s*\%#')
    return s:indent()+b:i_struct
  endif

  " let after another value-level construct
  if getline(a:l) =~ '^\s*let\>' && (OMLetAtomBackward() || search(';;\_s*\%#'))
    if OMLetBegendBackward()
      return s:indent()+b:i_struct
    else
      return 0
    endif
  else
    exe a:l
    " That was undoing the AtomBackward
  endif

  " let/and
  if getline(a:l) =~ '^\s*and\>' && OMLetBlockBackward('',0)
    if s:search('\%(\<let\>\|\<and\>\)\_[^=]\+=\_s*\%#')
      return s:indent()
    else
      exe a:l
    endif
  endif

  " Now we deal with let/in
  if getline(a:l) =~ '^\s*in\>' && s:searchpair('\<let\>','','\<in\>','bW')
    " Check that we don't have a toplevel let
    if s:indent() == s:topindent('.')
      exe a:l
    else
      return s:indent()
    endif
  endif

  " let after let isn't indented
  if getline(a:l) =~ '^\s*\<let\>' && s:search('\<in\>\_s*\%#')
    call s:searchpair('\<let\>','','\<in\>','bW')
    return s:indent()
  endif

  " }}}

  " {{{ Beginning of blocks
  " Howto indent a line after some keyword

  " Basic case
  if s:search('\(\<struct\>\|\<sig\>\|\<class\>\)\_s*\%#')
    return s:indent()+b:i_struct
  endif
  if s:search('\(\<while\>\|\<for\>\|\<if\>\|\<begin\>\|\<match\>\|\<try\>\|(\|{\|\[\|\[|\|\<initializer\>\)\_s*\%#')
    return s:indent()+b:i
  endif
  if s:search('\%(\<let\>\|\<and\>\|\<module\>\|\<val\>\|\<method\>\)\_[^=]\+=\_s*\%#')
    return s:indent()+b:i
  endif

  " PATTERNS
  if s:search('\<function\>\_s*\%#')
    return s:indent()+2+b:i_function
  endif
  if s:search('\<with\>\_s*\%#')
    call s:searchpair('\%(\<match\>\|\<try\>\)','','\<with\>','bW')
    return s:indent()+2+b:i_match
  endif
  if s:search('\<type\>\_[^=]\+=\_s*\%#')
    return s:indent()+2+b:i
  endif
  if s:search('\<of\>\_s*\%#')
    return s:indent()+b:i
  endif

  " Sometimes you increment according to a master keyword

  " IF
  if s:search('\<then\>\_s*\%#')
    call s:searchpair('\<if\>','','\<then\>','bW')
    return s:indent()+b:i
  endif
  if s:search('\<else\>\_s*\%#')
    call OMLetBlockBackward('then',0)
    call OMLetIfHeadBackward()
    return s:indent()+b:i
  endif

  " MATCH
  if s:search('\<when\>\_s*\%#')
    call OMLetPatternBackward()
    if search('\%#|')
      return s:indent(1)+2+b:i
    else
      " First pattern can have no |
      return s:indent()+b:i
    endif
  endif
  if s:search('->\_s*\%#')
    call OMLetPatternBackward()
    if s:search('fun\>\s*\%#')
      return s:indent()+b:i
    elseif search('\%#|')
      return s:indent(1)+2+b:i
    else
      " First pattern can have no |
      return s:indent()+b:i
    endif
  endif

  " WHILE/DO
  if s:search('\<do\>\_s*\%#')
    call s:searchpair('\%(\<while\>\|\<for\>\)','','\<do\>','bW')
    return s:indent()+b:i
  endif

  " LET
  if s:search('\<in\>\_s*\%#')
    call s:searchpair('\<let\>','','\<in\>','bW')
    return s:indent()+b:i_let
  endif

  " }}}

  " Sequence: find previous instruction's base indentation

  if s:search(';;\_s*\%#')
    if OMLetBegendBackward()
      return s:indent()+b:i_struct
    else
      return 0
    endif
  endif

  if s:search(';\_s*\%#')
    " Flexible indentation using s:indent() would be nice,
    " but I would actually need to return the identation
    " that *would have had* the previous expr in the sequence
    " if it has been alone on a line.
    " s/col(".")-1/s:indent()/ leads to bad things like:
    " > let x = bla ;
    " > bla
    call OMLetBlockBackward(';',0)
    while s:search(';\s*\%#')
      call OMLetBlockBackward(';',0)
    endwhile
    return col(".")-1
  endif

  if s:search(s:binop)
    call OMLetEBackward()
    return col(".")-1
  endif

  " = is a special binop
  if s:search('=\_s*\%#')
    call OMLetEBackward()
    return s:indent()+b:i
  endif

  " Application: indentation between a function and its arguments

  if OMLetAtomBackward()
    " I think s:indent() is ugly here...
    call OMLetABackward()
    return col('.')-1+b:i
  endif

  " This shouldn't happen
  return 0

endfunction

" }}}
