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
"
" TODO:
"   1. Add `Ignore` List
"   2. Smarter autocmd events

if exists('g:loaded_ModifiedFileHighlight') || (v:version < 730) || (! has('gui_running') && &t_Co <= 2) || (!exists('+colorcolumn'))
    finish
endif
let g:loaded_ModifiedFileHighlight = 1

function! s:ShowModifiedBufferStatus()
  let l:page = 1
  for i in tabpagebuflist()
    let l:range = ""

    if getbufvar(i, '&mod') && g:modifiedfilehighlight
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
    call setwinvar(l:page, '&colorcolumn', l:range)
    let l:page = l:page+1
  endfor
endfunction


function s:ShowModifiedBufferInnit(...)
  augroup ShowModifiedBuffer

    if g:modifiedfilehighlight
      autocmd BufWinEnter,WinEnter,CmdwinEnter,CursorHold,CursorHoldI,BufWritePost * call s:ShowModifiedBufferStatus()

      if &cursorline
        autocmd WinEnter * set cursorline
        autocmd WinLeave * set nocursorline
      endif

      if exists('##OptionSet')
        autocmd OptionSet modified call s:ShowModifiedBufferStatus()
      endif
    else
      call s:ShowModifiedBufferStatus()
    endif
  augroup END
endfunction

if !(exists('g:modifiedfilehighlight'))
  " if not defined, auto set to on
  let g:modifiedfilehighlight=1
endif

" Basic On + Off Commands
command! ModifiedFileHighlightOn let g:modifiedfilehighlight=1 | call s:ShowModifiedBufferInnit()
command! ModifiedFileHighlightOff let g:modifiedfilehighlight=0 | call s:ShowModifiedBufferInnit()


call s:ShowModifiedBufferInnit()
