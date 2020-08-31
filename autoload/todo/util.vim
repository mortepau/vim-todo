function! todo#util#get_indent_size()
    if &shiftwidth > 0 && &expandtab
        return &shiftwidth
    else
        return &tabstop
    endif
endfunction

function! todo#util#is_complete(line)
    return match(a:line, '^\s*\[\((x)\|x\)\] - .*$') == 0
endfunction

function! todo#util#is_partial(line)
    return match(a:line, '^\s*\[\((/)\|/\)\] - .*$') == 0
endfunction

function! todo#util#is_incomplete(line)
    return match(a:line, '^\s*\[\(( )\| \)\] - .*$') == 0
endfunction

function! todo#util#is_active(line)
    return match(a:line, '^\s*\[(\(x\|/\| \))\] - .*$') == 0
endfunction

function! todo#util#is_header(line)
    return match(a:line, '^/s*[^#[].*') == 0
endfunction

function! todo#util#is_comment(line)
    return match(a:line, '#.*') == 0
endfunction

function! todo#util#is_empty(line)
    return match(a:line, '^\s*$') == 0
endfunction

function! todo#util#is_task(line)
    return todo#util#is_complete(a:line) || 
         \ todo#util#is_partial(a:line) ||
         \ todo#util#is_incomplete(a:line)
endfunction
