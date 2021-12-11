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
"   1. Remove Nested Loop
"   2. Smarter autocmd events
"   3. Add `Ignore` List
"   4. Testing


if exists('g:loaded_ModifiedFileHighlight') || (v:version < 730) || (! has('gui_running') && &t_Co <= 2) || (!exists('+colorcolumn'))
    finish
endif
let g:loaded_SModifiedFileHighlight= 1

function! s:ShowModifiedBufferStatus()
  let l:page = 1
  for i in tabpagebuflist()
    let l:range = ""
    let l:changed = 0

    for j in getbufinfo()
      if j.bufnr == i
        let l:changed = j.changed
        break
      endif
    endfor

    if l:changed == 1
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

augroup ShowModifiedBuffer
  au!

  autocmd BufWinEnter,WinEnter,CmdwinEnter,CursorHold,CursorHoldI,BufWritePost * call s:ShowModifiedBufferStatus()

  if &cursorline
    au WinEnter * set cursorline
    au WinLeave * set nocursorline
  endif

  if exists('##OptionSet')
    autocmd OptionSet modified call s:ShowModifiedBufferStatus()
  endif
augroup END


