if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

setlocal shiftwidth=2
setlocal softtabstop=2
setlocal expandtab
setlocal noautoindent

if g:todo_enable_active_status
    nnoremap <buffer> <silent> <Plug>(vim-todo-active) :call todo#toggle_status()<CR>
endif

inoremap <buffer> <silent> <Plug>(vim-todo-new)      <CMD>call todo#new_line()<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-new-inline) <CMD>call todo#new_task()<CR>

nnoremap <buffer> <silent> <Plug>(vim-todo-o) :call todo#new_below()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-O) :call todo#new_above()<CR>

nnoremap <buffer> <silent> <Plug>(vim-todo-complete) :call todo#toggle_completion()<CR>
xnoremap <buffer> <silent> <Plug>(vim-todo-complete) :call todo#toggle_completion()<CR>

nnoremap <buffer> <silent> <Plug>(vim-todo-sort)     :1,$call todo#sort()<CR>
xnoremap <buffer> <silent> <Plug>(vim-todo-sort)     :call todo#sort()<CR>

nnoremap <buffer> <silent> <Plug>(vim-todo-indent)   :call todo#indent(mode())<CR>
xnoremap <buffer> <silent> <Plug>(vim-todo-indent)   :call todo#indent(mode())<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-indent)   <CMD>call todo#indent(mode())<CR>

nnoremap <buffer> <silent> <Plug>(vim-todo-outdent)  :call todo#indent(mode())<CR>
xnoremap <buffer> <silent> <Plug>(vim-todo-outdent)  :call todo#indent(mode())<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-outdent)  <CMD>call todo#indent(mode())<CR>

if g:todo_enable_default_bindings
    silent! nmap <buffer> <silent> o <Plug>(vim-todo-o)
    silent! nmap <buffer> <silent> O <Plug>(vim-todo-O)

    if g:todo_enable_active_status
        silent! nmap <buffer> <silent> <SPACE> <Plug>(vim-todo-active)
    endif

    execute("silent! imap <buffer> <silent> " . g:todo_inline_template[-1:-1] . " <Plug>(vim-todo-new-inline)")
    " silent! imap <buffer> <silent> <expr> g:todo_inline_template[-1] <Plug>(vim-todo-new-inline)
    silent! imap <buffer> <silent> <CR> <Plug>(vim-todo-new)

    silent! nmap <buffer> <silent> <CR> <Plug>(vim-todo-complete)
    silent! xmap <buffer> <silent> <CR> <Plug>(vim-todo-complete)

    silent! nmap <buffer> <silent> R <Plug>(vim-todo-sort)
    silent! xmap <buffer> <silent> R <Plug>(vim-todo-sort)
    
    silent! nmap <buffer> <silent> X <Plug>(vim-todo-remove)
    silent! xmap <buffer> <silent> X <Plug>(vim-todo-remove)

    silent! nmap <buffer> <silent> <TAB> <Plug>(vim-todo-indent)
    silent! xmap <buffer> <silent> <TAB> <Plug>(vim-todo-indent)
    silent! imap <buffer> <silent> <TAB> <Plug>(vim-todo-indent)

    silent! nmap <buffer> <silent> <S-TAB> <Plug>(vim-todo-outdent)
    silent! xmap <buffer> <silent> <S-TAB> <Plug>(vim-todo-outdent)
    silent! imap <buffer> <silent> <S-TAB> <Plug>(vim-todo-outdent)
endif

" iabbrev <buffer> <expr> new todo#new_task()

" Sort all the lines in the given range, based on certain criteria
command! -buffer -range TodoSort <line1>,<line2>call todo#sort()

" Convert the lines in the given range into valid task entries
command! -buffer -nargs=? -range TodoConvert <line1>,<line2>call todo#convert(<q-args>)

" Rebuild the tree structure of the file, in case it breaks
command! -buffer TodoRefresh call todo#refresh()

" Hide virtual text
command! -buffer TodoHide call todo#hide_virtual_text()

" Show virtual text
command! -buffer TodoShow call todo#show_virtual_text()

augroup Todo
    autocmd!
    autocmd BufEnter *.todo,todo call todo#initialize()
    autocmd InsertLeave *.todo,todo call todo#update()
    autocmd User TodoChange call todo#change()
augroup END
