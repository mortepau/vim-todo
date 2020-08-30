if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

setlocal comments=:#
setlocal commentstring=#\ %s
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal expandtab

nnoremap <buffer> <silent> o <cmd>call todo#new_below()<cr>
nnoremap <buffer> <silent> O <cmd>call todo#new_above()<cr>
nnoremap <buffer> <silent> <CR> <cmd>call todo#toggle_completion()<cr>
nnoremap <buffer> <silent> <SPACE> <cmd>call todo#toggle_active()<cr>
nnoremap <buffer> <silent> <TAB> <cmd>call todo#indent(v:true)<cr>
nnoremap <buffer> <silent> <S-TAB> <cmd>call todo#indent(v:false)<cr>
nnoremap <buffer> <silent> R <cmd>1,$TodoSort<cr>
xnoremap <buffer> <silent> R :call todo#sort()<cr>

" command! -range TodoSort <line1>,<line2> call todo#sort()
command! -range TodoSort <line1>,<line2>call todo#sort()
