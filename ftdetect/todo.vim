autocmd BufRead,BufNewFile * call <SID>TodoDetectFiletype()

function! s:TodoDetectFiletype() 
    if !did_filetype() || &filetype !=# 'todo'
        if match(fnamemodify(expand('%'), ':p:t'), '\v\C^(.*\.)?(todo|Todo|TODO)$') == 0
            set filetype=todo 
        endif
    endif
endfunction

