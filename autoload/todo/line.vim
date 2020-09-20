function! todo#line#new(line, linenr)
    let empty = match(a:line, '^\s*$' ) != -1
    let open = match(a:line, "\\V" . g:todo_completion_templates.open) != -1
    let closed = match(a:line, "\\V" . g:todo_completion_templates.closed) != -1
    let partial = g:todo_enable_partial_completion && match(a:line, "\\V" . g:todo_completion_templates.partial) != -1

    if g:todo_enable_active_status
        let active = match(a:line, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates.open) != -1
        if g:todo_enable_partial_completion
            let active = active || match(a:line, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates.partial) != -1
        endif
        let active = active || match(a:line, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates.closed) != -1
    else
        let active = v:false
    endif
    let indent = empty ? 0 : indent(a:linenr) / shiftwidth()

    if open
        let kind = 'open'
    elseif closed
        let kind = 'closed'
    elseif partial
        let kind = 'partial'
    elseif active
        let kind = 'active'
    elseif empty
        let kind = 'empty'
    else
        let kind = 'other'
    endif

    let line = {
        \ '__struct__': 'line',
        \ 'value': a:line,
        \ 'linenr': a:linenr,
        \ 'indent': indent,
        \ 'kind': kind,
        \ 'status': active,
        \ 'children': [],
        \ 'num_children': 0,
        \ 'parent': -1,
        \ 'progress': 0,
        \ }

    return line
endfunction

function! todo#line#build(lines)
    let line_indents = {}
    let indent = 0

    for line in a:lines
        " No need to insert empty lines into the node tree
        if line.kind ==? 'empty'
            continue
        endif

        " Insert line in the dictionary at the key matching their indent,
        " this ensures that we can always find the parent using their indent
        if has_key(line_indents, line.indent)
            let line_indents[line.indent] += [line]
        else
            let line_indents[line.indent] = [line]
        endif

        " If it isn't a 0 indent line it means it has a parent
        if line.indent != 0
            let line.parent = line_indents[line.indent - 1][-1].linenr
            let line_indents[line.indent - 1][-1].children += [line]
            let line_indents[line.indent  -1][-1].num_children += 1
        endif

        " Update the indent to match the current line's
        let indent = line.indent
    endfor

    " Return all entries in the 0 indent key
    return line_indents[0]
endfunction

function! todo#line#draw(line)
    if <SID>Valid(a:line)
        if a:line.kind !=? 'other' && a:line.kind !=? 'empty' && a:line.indent == 0 && a:line.linenr != 1
            call setline(a:line.linenr - 1, "")
        endif
        call setline(a:line.linenr, a:line.value)
        if a:line.num_children > 0
            for child in a:line.children
                call todo#line#draw(child)
            endfor
        endif
    endif
endfunction

function! todo#line#sort(lines)
    " Recurse down first
    for line in a:lines
        if line.num_children > 0
            call todo#line#sort(line.children)
        endif
    endfor

    let changed = v:true
    while changed
        let changed = v:false
        for i in range(len(a:lines)-1)
            if <SID>Compare(a:lines[i], a:lines[i+1])
                let next = <SID>UpdateLinenr(a:lines[i+1], a:lines[i].linenr)
                call <SID>UpdateLinenr(a:lines[i], next)
                let [a:lines[i], a:lines[i+1]] = [a:lines[i+1], a:lines[i]]
                let changed = v:true
            endif
        endfor
    endwhile
endfunction

function! s:Compare(line_a, line_b)
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

function! s:Valid(line)
   if type(a:line) != v:t_dict
       return v:false
   endif
   return has_key(a:line, '__struct__') && a:line.__struct__ ==? 'line'
endfunction

function! s:UpdateLinenr(lines, start)
    let curr = a:start
    if type(a:lines) == v:t_list
        for line in a:lines
            if line.indent == 0
                let curr += 1
            endif
            let line.linenr = curr
            let curr += 1
            if line.num_children > 0
                let curr = <SID>UpdateLinenr(line.children, curr)
            endif
        endfor
    else
        let a:lines.linenr = curr
        let curr += 1
        if line.num_children > 0
            let curr = <SID>UpdateLinenr(a:lines.children, curr)
        endif
    endif

    return curr
endfunction

function! s:Debug(lines)
    let line_length = 80
    if type(a:lines) == v:t_list
        for line in a:lines
            call <SID>Debug(line)
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
        let linechildren = "| Children: " . line.num_children
        let l += [linechildren]
        let lineparent = "| Parent  : " . line.parent
        let l += [lineparent]

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
        if line.num_children > 0
            call <SID>Debug(line.children)
        endif
    endif
endfunction
