if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

setlocal shiftwidth=2
setlocal softtabstop=2
setlocal expandtab

nnoremap <buffer> <silent> o <cmd>call todo#new_below()<cr>
nnoremap <buffer> <silent> O <cmd>call todo#new_above()<cr>
nnoremap <buffer> <silent> <SPACE> <cmd>call todo#toggle_status()<cr>

nnoremap <buffer> <silent> <CR> <cmd>call todo#toggle_completion()<cr>
xnoremap <buffer> <silent> <CR> :call todo#toggle_completion()<cr>
inoremap <buffer> <silent> <CR> <cmd>call todo#new_line()<cr>

nnoremap <buffer> <silent> R <cmd>1,$TodoSort<cr>
xnoremap <buffer> <silent> R :call todo#sort()<cr>

nnoremap <buffer> <silent> <TAB> <cmd>call todo#indent(v:true, mode())<cr>
inoremap <buffer> <silent> <TAB> <cmd>call todo#indent(v:true, mode())<cr>
xnoremap <buffer> <silent> <TAB> :call todo#indent(v:true, mode())<cr>
nnoremap <buffer> <silent> <S-TAB> <cmd>call todo#indent(v:false, mode())<cr>
inoremap <buffer> <silent> <S-TAB> <cmd>call todo#indent(v:false, mode())<cr>
xnoremap <buffer> <silent> <S-TAB> :call todo#indent(v:false, mode())<cr>

iabbrev <buffer> <expr> new todo#new_task()

command! -range TodoSort <line1>,<line2>call todo#sort()
