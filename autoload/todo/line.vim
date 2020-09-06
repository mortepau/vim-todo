function! todo#line#new(line, linenr)
    let indent = todo#line#find_indent(a:line)
    let status = todo#line#find_status(a:line)
    let kind = todo#line#find_kind(a:line)
    let line = {
        \ '__struct__': 'line',
        \ 'value': a:line,
        \ 'linenr': a:linenr,
        \ 'indent': indent,
        \ 'kind': kind,
        \ 'status': status,
        \ 'marker': todo#marker#new(),
        \ 'children': [],
        \ 'num_children': 0,
        \ }
    call todo#line#find_marker(line)
    return line
endfunction

function! todo#line#find_indent(line)
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

function! todo#line#find_status(line)
    let line = todo#line#to_string(a:line)
    return todo#util#is_active(line)
endfunction

function! todo#line#find_kind(line)
    let line = todo#line#to_string(a:line)
    if todo#util#is_closed(line)
        let v = 'closed'
    elseif todo#util#is_partial(line)
        let v = 'partial'
    elseif todo#util#is_open(line)
        let v = 'open'
    elseif todo#util#is_empty(line)
        let v = 'empty'
    else
        let v = 'other'
    endif
    return v
endfunction

function! todo#line#find_marker(line)
    " Do nothing if the current line is not a task
    if a:line.kind ==? 'empty' || a:line.kind ==? 'other'
        return
    endif
    let value = g:todo_conversion_table['marker'][a:line.kind]
    if a:line.status
        let value = '(' . value . ')'
    endif

    let start = a:line.indent * todo#util#get_indent_size() + 1

    call todo#marker#set_value(a:line.marker, value)
    call todo#marker#set_start(a:line.marker, start)
endfunction

function! todo#line#insert_child(line, child)
    if todo#line#valid(a:line)
        call add(a:line.children, a:child)
        let a:line.num_children += 1
        let a:line.num_children += a:child.num_children
    endif
endfunction

function! todo#line#has_children(line)
    if todo#line#valid(a:line)
        return a:line.num_children > 0
    endif
    return v:false
endfunction

function! todo#line#num_children(line)
    if todo#line#valid(a:line)
        return len(a:line.children)
    endif
    return 0
endfunction

function! todo#line#rearrange(lines)
    let block = remove(a:lines, -1)
    while !empty(a:lines)
        let pblock = remove(a:lines, -1)
        if block[-1].indent > pblock[-1].indent
            for element in block
                call todo#line#insert_child(pblock[-1], element)
            endfor
        elseif block[-1].indent < pblock[-1].indent
            if todo#line#has_children(pblock[-1])
                let potential_parent = block[-1]
                for child in pblock[-1].children
                    if child.indent == pblock.indent
                        let potential_parent = child
                    endif
                endfor
                for element in pblock
                    call todo#line#insert_child(potential_parent, element)
                endfor
            endif
        else
            call add(a:lines, pblock)
            break
        endif
        let block = pblock
    endwhile
    call add(a:lines, block)
endfunction

function! todo#line#to_string(line)
    if todo#line#valid(a:line)
        return a:line.value
    else
        return a:line
    endif
endfunction

function! todo#line#write(line, string)
    if todo#line#valid(a:line)
        let new_line = todo#line#new(a:string, a:line.linenr)
        let a:line.value = new_line.value
        let a:line.indent = new_line.indent
        let a:line.kind = new_line.kind
        let a:line.status = new_line.status
        let a:line.marker = new_line.marker
    endif
endfunction

function! todo#line#draw(line)
    if todo#line#valid(a:line)
        if a:line.kind !=? 'other' && a:line.kind !=? 'empty' && a:line.indent == 0 && a:line.linenr != 1
            call setline(a:line.linenr - 1, "")
        endif
        call setline(a:line.linenr, a:line.value)
        if todo#line#has_children(a:line)
            for child in a:line.children
                call todo#line#draw(child)
            endfor
        endif
    endif
endfunction

function! todo#line#compare(line_a, line_b)
    " Validate if both are lines
    if !todo#line#valid(a:line_b)
        return v:false
    endif
    if !todo#line#valid(a:line_a)
        return v:true
    endif

    " Validate if any of them are comments
    if todo#util#is_comment(a:line_a.value) || todo#util#is_comment(a:line_b.value)
        return v:false
    endif

    " Validate status
    if a:line_a.status != a:line_b.status
        return a:line_b.status
    endif

    if a:line_a.kind ==? a:line_b.kind
        return v:false
    elseif a:line_a.kind ==? 'open'
        return v:false
    elseif a:line_b.kind ==? 'open'
        return v:true
    else
        return a:line_b.kind ==? 'partial'
    endif
endfunction

function! todo#line#valid(line)
   if type(a:line) != v:t_dict
       return v:false
   endif
   return has_key(a:line, '__struct__') && a:line.__struct__ ==? 'line'
endfunction

function! todo#line#update_linenr(lines, start)
    let curr = a:start
    if type(a:lines) == v:t_list
        for line in a:lines
            if line.indent == 0
                let curr += 1
            endif
            let line.linenr = curr
            let curr += 1
            if todo#line#has_children(line)
                let curr = todo#line#update_linenr(line.children, curr)
                " let curr += line.num_children
            endif
        endfor
    else
        let a:lines.linenr = curr
        let curr += 1
        if todo#line#has_children(a:lines)
            let curr = todo#line#update_linenr(a:lines.children, curr)
            " let curr += a:lines.num_children
        endif
    endif

    return curr
endfunction

function! todo#line#sort(lines)
    " Recurse down first
    for line in a:lines
        if todo#line#has_children(line)
            call todo#line#sort(line.children)
        endif
    endfor

    let changed = v:true
    while changed
        let changed = v:false
        for i in range(len(a:lines)-1)
            if todo#line#compare(a:lines[i], a:lines[i+1])
                " call todo#line#update_linenr(a:lines[i+1], a:lines[i].linenr)
                " call todo#line#update_linenr(a:lines[i], a:lines[i+1].linenr + a:lines[i+1].num_children + 1)
                let next = todo#line#update_linenr(a:lines[i+1], a:lines[i].linenr)
                call todo#line#update_linenr(a:lines[i], next)
                let [a:lines[i], a:lines[i+1]] = [a:lines[i+1], a:lines[i]]
                let changed = v:true
            endif
        endfor
    endwhile
endfunction

function! todo#line#print(lines)
    let line_length = 80
    if type(a:lines) == v:t_list
        for line in a:lines
            call todo#line#print(line)
        endfor
    else
        let line = a:lines
        let l = []
        let linenr = "| Linenr  : " . line.linenr
        let l += [linenr]
        let linevalue = "| Value   : \"" . line.value . "\""
        let l += [linevalue]
        let lineindent = "| Indent  : " . line.indent
        let l += [lineindent]
        let linestatus = "| Status  : " . (line.status ? "Inactive" : "Active")
        let l += [linestatus]
        let linekind = "| Kind    : " . line.kind
        let l += [linekind]
        let linemarker = "| Marker  : " . "Start: " . line.marker.start . ", End: " . line.marker.end . ", Value: " . line.marker.value
        let l += [linemarker]
        let linechildren = "| Children: " . line.num_children
        let l += [linechildren]

        echom repeat(" ", line.indent * 4) . repeat('-', line_length)
        for v in l
            let out = v
            if len(v) > line_length
                let out = v[0:line_length-1]
            else
                let diff = line_length - len(v)
                let out = out . repeat(" ", diff)
            endif
            echom repeat(" ", line.indent * 4) . out
        endfor
        if todo#line#has_children(line)
            call todo#line#print(line.children)
        endif
    endif
endfunction
