function! todo#line#new(line, linenr)
    let indent = todo#line#get_indent(a:line)
    let status = todo#line#get_status(a:line)
    let completion = todo#line#get_completion(a:line)
    let line = {
        \ '__struct__': 'line',
        \ 'value': a:line,
        \ 'linenr': a:linenr,
        \ 'indent': indent,
        \ 'completion': completion,
        \ 'status': status,
        \ 'marker': todo#marker#new(),
        \ }
    call todo#line#get_marker(line)
    return line
endfunction

function! todo#line#get_indent(line)
    let line = todo#line#to_string(a:line)
    if todo#util#is_empty(line)
        return 0
    endif
    let indent_size = todo#util#get_indent_size()
    let indents = 0
    let index = 0
    while (match(line[index:index+indent_size-1], '\s\{' . indent_size . '\}') != -1)
        let index += indent_size
        let indents += 1
    endwhile
    return indents
endfunction

function! todo#line#get_status(line)
    let line = todo#line#to_string(a:line)
    return todo#util#is_active(line)
endfunction

function! todo#line#get_completion(line)
    let line = todo#line#to_string(a:line)
    if todo#util#is_complete(line)
        let v = 'complete'
    elseif todo#util#is_partial(line)
        let v = 'partial'
    elseif todo#util#is_incomplete(line)
        let v = 'incomplete'
    elseif todo#util#is_header(line)
        let v = 'header'
    elseif todo#util#is_comment(line)
        let v = 'comment'
    else
        let v = 'default'
    endif
    return g:todo_completion_to_integer[v]
endfunction

function! todo#line#get_marker(line)
    let value = g:todo_completion_to_marker[a:line.completion]
    if a:line.status
        let value = '(' . value . ')'
    endif

    let start = a:line.indent * todo#util#get_indent_size() + 1

    call todo#marker#set_value(a:line.marker, value)
    call todo#marker#set_start(a:line.marker, start)
endfunction

function! todo#line#to_string(line)
    if todo#line#valid(a:line)
        return a:line.value
    else
        return a:line
    endif
endfunction

function! todo#line#read(line)
    if todo#line#valid(a:line)
        return a:line.value
    else
        return ''
    endif
endfunction

function! todo#line#write(line, string)
    if todo#line#valid(a:line)
        let new_line = todo#line#new(a:string, a:line.linenr)
        let a:line.value = new_line.value
        let a:line.indent = new_line.indent
        let a:line.completion = new_line.completion
        let a:line.status = new_line.status
        let a:line.marker = new_line.marker
    endif
endfunction

function! todo#line#draw(line)
    if todo#line#valid(a:line)
        call setline(a:line.linenr, a:line.value)
    endif
endfunction

function! todo#line#valid(line)
   if type(a:line) != v:t_dict
       return v:false
   endif
   return has_key(a:line, '__struct__') && a:line.__struct__ ==? 'line'
endfunction
