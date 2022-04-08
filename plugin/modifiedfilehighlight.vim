" modifiedfilehighlight.vim: Highlight Windows with Modified Buffers Open
"
" Dependencies:
"   Assumption is Vim v7.3, but unknown when
"     `getbufinfo()` and `OptionSet` was added.
"
" Editer: Neal Joslin
"
" Sources:
"   vim-diminactive           https://github.com/blueyed/vim-diminactive
"       Base Loop, ColorColumn Hightlight Mechanic
"
"   vim-StatusLineHighlight   https://github.com/inkarkat/vim-StatusLineHighlight
"       autocmd events for when to check if Modified
"
" Note: Change Color of bg by changing `ColorColumn` (Highlight)

" Global Settings {{{

if exists('g:loaded_ModifiedFileHighlight') || (v:version < 730) || (! has('gui_running') && &t_Co <= 2) || (!exists('+colorcolumn'))
    finish
endif
let g:loaded_ModifiedFileHighlight = 1

if !(exists('g:modifiedfilehighlight'))
  let g:modifiedfilehighlight=1
endif

" }}}

" User Settings {{{

if !(exists('g:modifiedfilehighlight_ignore_no_name'))
  let g:modifiedfilehighlight_ignore_no_name=1
endif

let g:modifiedfilehighlight_modifieddict={}

" }}}

" Dictionary Functions {{{

" Dictionary Checks {{{

function! s:ModifiedBufferStatusInDict(tab, page)
  return has_key(g:modifiedfilehighlight_modifieddict,a:tab) && has_key(get(g:modifiedfilehighlight_modifieddict,a:tab),a:page)
endfunction

function! s:ModifiedBufferStatusBufferChange(tab, page, buffname)
  " Checks if buff in tab.page is the current
  return get(get(g:modifiedfilehighlight_modifieddict,a:tab),a:page) != a:buffname
endfunction

" }}}

" Dictionary Edits {{{

function! s:ModifiedBufferStatusAddItem(tab, page, buffname)
  if has_key(g:modifiedfilehighlight_modifieddict,a:tab)
    let g:modifiedfilehighlight_modifieddict[a:tab][a:page] = a:buffname
  else
    let g:modifiedfilehighlight_modifieddict[a:tab] = {a:page: a:buffname}
  endif
endfunction

function! s:ModifiedBufferStatusDelItem(tab, page)
  if has_key(g:modifiedfilehighlight_modifieddict,a:tab)
    if has_key(get(g:modifiedfilehighlight_modifieddict,a:tab),a:page)
      unlet g:modifiedfilehighlight_modifieddict[a:tab][a:page]
    endif
    if (empty(g:modifiedfilehighlight_modifieddict[a:tab]))
      unlet g:modifiedfilehighlight_modifieddict[a:tab]
    endif
  endif
endfunction

" }}}

" }}}

" Main Function {{{

function! s:ShowModifiedBufferStatus(...)
  if g:modifiedfilehighlight
    let l:tab = tabpagenr()
    let l:page = 1

    " Loop Through Buffers on Page {{{
    for buff in tabpagebuflist()
      let l:range = ''
      let l:indict = s:ModifiedBufferStatusInDict(l:tab, l:page)
      let l:buffname = bufname(buff)

      if getbufvar(buff, '&mod') && (!(l:indict) || s:ModifiedBufferStatusBufferChange(l:tab, l:page, l:buffname))
        " Buffer is modified and item isn't list or a new Buffer just loaded in Window
        let l:skip = 0

        " Skip Check {{{

        if g:modifiedfilehighlight_ignore_no_name==1 && len(l:buffname) == 0
          let l:skip = 1
        elseif exists('g:modifiedfilehighlight_ignore')
          let l:skip = !(empty(matchstr(l:buffname, g:modifiedfilehighlight_ignore)))
        endif

        " }}}

        " ColorColumn Range {{{
        if !(l:skip)
          if &wrap
           " HACK: when wrapping lines is enabled, we use the maximum number
           " of columns getting highlighted. This might get calculated by
           " looking for the longest visible line and using a multiple of
           " winwidth().
           let l:width=256 " max
          else
           let l:width=winwidth(l:page)
          endif
          let l:range = join(range(1, l:width), ',')
        endif
        " }}}

        " Draw the color column
        call settabwinvar(l:tab, l:page, '&colorcolumn', l:range)

        " Add item to Nested Dict
        call s:ModifiedBufferStatusAddItem(l:tab, l:page, l:buffname)

      elseif !(getbufvar(buff, '&mod')) && getwinvar(l:page, '&colorcolumn')
        " Buffer isn't modified and ColorColumn is drawn

        call settabwinvar(l:tab, l:page, '&colorcolumn', l:range)

        if l:indict
          " Remove item to Nested Dict
          call s:ModifiedBufferStatusDelItem(l:tab, l:page)
        endif

      endif

      let l:page = l:page+1
    endfor

    " }}}

  elseif a:0

    " Modified Turned Off {{{

    " Remove ColorColumn on **all** Buffers on **all** tabs
    if !(empty(g:modifiedfilehighlight_modifieddict))
      for tab in keys(g:modifiedfilehighlight_modifieddict)
        for page in keys(get(g:modifiedfilehighlight_modifieddict,tab))
          call settabwinvar(tab, page, '&colorcolumn', '')
          call s:ModifiedBufferStatusDelItem(tab, page)
        endfor
      endfor
    endif

    " }}}

  endif
endfunction

" }}}

" autocmd Triggers {{{

function s:ShowModifiedBufferInnit(...)
  augroup ShowModifiedBuffer

    if g:modifiedfilehighlight

      if a:0
        " Turn On.
        call s:ShowModifiedBufferStatus()
      else
        " First innit
        autocmd TextChanged,TextChangedI,BufWinEnter,TabEnter,BufWritePost  * call s:ShowModifiedBufferStatus()

        if &cursorline
          autocmd WinEnter * set cursorline
          autocmd WinLeave * set nocursorline
        endif

        if exists('##OptionSet')
          autocmd OptionSet modified call s:ShowModifiedBufferStatus()
        endif
      endif

    else
      " Turn Off. Turn off active colorcolumns
      call s:ShowModifiedBufferStatus(1)
    endif
  augroup END
endfunction

" }}}

" Define User Commands {{{

command! ModifiedFileHighlightOn let g:modifiedfilehighlight=1 | call s:ShowModifiedBufferInnit(1)
command! ModifiedFileHighlightOff let g:modifiedfilehighlight=0 | call s:ShowModifiedBufferInnit(1)

" }}}

" Call autocmd trigger innit
call s:ShowModifiedBufferInnit()

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
