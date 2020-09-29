if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

setlocal shiftwidth=2
setlocal softtabstop=2
setlocal expandtab
setlocal noautoindent

if g:todo_enable_active_status
    nnoremap <buffer> <silent> <Plug>(vim-todo-active) :call TodoToggleActive()<CR>
endif

inoremap <buffer> <silent> <Plug>(vim-todo-new-inline) <CMD>call TodoNewTaskInline()<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-new)        <CMD>call TodoNewTask()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-o)          :call TodoOpenTaskBelow()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-O)          :call TodoOpenTaskAbove()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-I)          :call TodoInsert()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-A)          :call TodoAppend()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-complete)   :call TodoToggleCompletion()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-indent)     :call TodoIndent(mode(), v:false)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-indent)     <CMD>call TodoIndent(mode(), v:false)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-indent-g)   :call TodoIndent(mode(), v:true)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-indent-g)   <CMD>call TodoIndent(mode(), v:true)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-deindent)   :call TodoDeindent(mode(), v:false)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-deindent)   <CMD>call TodoDeindent(mode(), v:false)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-deindent-g) :call TodoDeindent(mode(), v:true)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-deindent-g) <CMD>call TodoDeindent(mode(), v:true)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-next-header) :call TodoHeaderNext()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-prev-header) :call TodoHeaderPrev()<CR>

if g:todo_enable_default_bindings
    silent! nmap <buffer> <silent> o <Plug>(vim-todo-o)
    silent! nmap <buffer> <silent> O <Plug>(vim-todo-O)
    silent! nmap <buffer> <silent> I <Plug>(vim-todo-I)
    silent! nmap <buffer> <silent> A <Plug>(vim-todo-A)

    if g:todo_enable_active_status
        silent! nmap <buffer> <silent> <SPACE> <Plug>(vim-todo-active)
    endif

    execute("silent! imap <buffer> <silent> " . g:todo_inline_template[-1:-1] . " <Plug>(vim-todo-new-inline)")

    silent! imap <buffer> <silent> <CR> <Plug>(vim-todo-new)

    silent! nmap <buffer> <silent> <CR> <Plug>(vim-todo-complete)
    silent! xmap <buffer> <silent> <CR> <Plug>(vim-todo-complete)

    silent! nmap <buffer> <silent> <TAB> <Plug>(vim-todo-indent)
    silent! imap <buffer> <silent> <TAB> <Plug>(vim-todo-indent)

    silent! nmap <buffer> <silent> g<TAB> <Plug>(vim-todo-indent-g)
    silent! imap <buffer> <silent> g<TAB> <Plug>(vim-todo-indent-g)

    silent! nmap <buffer> <silent> <S-TAB> <Plug>(vim-todo-deindent)
    silent! imap <buffer> <silent> <S-TAB> <Plug>(vim-todo-deindent)

    silent! nmap <buffer> <silent> g<S-TAB> <Plug>(vim-todo-deindent-g)
    silent! imap <buffer> <silent> g<S-TAB> <Plug>(vim-todo-deindent-g)

    silent! nmap <buffer> <silent> <C-n> <Plug>(vim-todo-next-header)
    silent! nmap <buffer> <silent> <C-p> <Plug>(vim-todo-prev-header)
endif

" Sort all the lines in the given range, based on certain criteria
command! -buffer TodoSort <line1>,<line2>call TodoSort()

" Convert the lines in the given range into valid task entries
command! -buffer -nargs=? TodoConvert <line1>,<line2>call TodoConvert(<q-args>)

" Hide virtual text
command! -buffer TodoHide call TodoHide()

" Show virtual text
command! -buffer TodoShow call TodoShow()

augroup Todo
    autocmd!
    autocmd BufEnter *.todo,todo call TodoInitialize()
augroup END
