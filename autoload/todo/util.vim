function! todo#util#template()
    return "[ ] - "
endfunction

function! todo#util#eol()
    return col('.') == col('$')
endfunction

function! todo#util#invert_dict(dict)
    if type(dict) != v:t_dict
        return {}
    endif

    let new_dict = {}
    for [key, value] in items(a:dict)
        let new_dict[value] = key
    endfor
    return new_dict
endfunction

function! todo#util#get_indent_size()
    if &shiftwidth > 0 && &expandtab
        return &shiftwidth
    else
        return &tabstop
    endif
endfunction

function! todo#util#is_closed(line)
    return match(a:line, '^\s*\[\((x)\|x\)\] - .*$') == 0
endfunction

function! todo#util#is_partial(line)
    return match(a:line, '^\s*\[\((/)\|/\)\] - .*$') == 0
endfunction

function! todo#util#is_open(line)
    return match(a:line, '^\s*\[\(( )\| \)\] - .*$') == 0
endfunction

function! todo#util#is_active(line)
    return match(a:line, '^\s*\[(\(x\|/\| \))\] - .*$') == 0
endfunction

function! todo#util#is_header(line)
    return match(a:line, '^\s*!.*') == 0
endfunction

function! todo#util#is_comment(line)
    return match(a:line, '//.*') == 0
endfunction

function! todo#util#is_empty(line)
    return match(a:line, '^\s*$') == 0
endfunction

function! todo#util#is_task(line)
    return todo#util#is_closed(a:line) || 
         \ todo#util#is_partial(a:line) ||
         \ todo#util#is_open(a:line)
endfunction
