function! todo#new_below()
    call feedkeys("o[ ] - ", 'n')
endfunction

function! todo#new_above()
    call feedkeys("O[ ] - ", 'n')
endfunction

function! todo#toggle_completion()
    call todo#init()
    let line = getline('.')
    let num_indents = todo#get_num_indents(line)
    let marker_pos = num_indents * todo#get_indent_size() + 1

    let complete   = match(line, s:complete_regex) != -1
    let incomplete = match(line, s:incomplete_regex) != -1
    let partial    = match(line, s:partial_regex) != -1
    let active     = match(line, s:active_regex) != -1

    if complete
        let marker = ' '
    elseif incomplete
        let marker = '/'
    elseif partial
        " If completing an active task, deactivate it
        if active
            call todo#toggle_active()
            let line = getline('.')
            let active = v:false
        endif
        let marker = 'x'
    else
        return
    endif

    if active
        let marker_pos += 1
    endif
    let new_line = line[0:marker_pos-1] . marker . line[marker_pos+1:]
    call setline('.', new_line)
endfunction

function! todo#toggle_active()
    call todo#init()
    let line = getline('.')
    let complete   = match(line, s:complete_regex) != -1
    let incomplete = match(line, s:incomplete_regex) != -1
    let partial    = match(line, s:partial_regex) != -1
    let active     = match(line, s:active_regex) != -1

    " Return if not a task
    if !complete && !incomplete && !partial
        return
    endif

    " Return if trying to make a complete task active
    if complete && !active
        return
    endif

    let marker_pos = todo#get_num_indents(line) * todo#get_indent_size() + 1

    if active
        let marker_pos += 1
        let new_line = line[0:marker_pos-2] . line[marker_pos] . line[marker_pos+2:]
    else
        let new_line = line[0:marker_pos-1] .'(' . line[marker_pos] . ')' . line[marker_pos+1:]
    endif

    call setline('.', new_line)
endfunction

function! todo#indent(indent)
    if a:indent
        call feedkeys('>>', 'n')
    else
        call feedkeys('<<', 'n')
    endif
endfunction

function! todo#sort() range
    call todo#init()
    let lines = getline(a:firstline, a:lastline)
    let indent = todo#get_num_indents(lines[0])
    let linenr = a:firstline
    let s:stack = []
    let block = todo#new_block()

    for value in lines
        " Ignore empty lines
        if match(value, "^\s*$") != -1
            let linenr += 1
            continue
        endif

        let line = {
            \ 'line': value,
            \ 'linenr': linenr,
            \ 'indent': todo#get_num_indents(value),
            \ 'active': match(value, s:active_regex) != -1,
            \ 'status': todo#get_line_status(value)
        \ }

        if line.indent > indent
            if len(block) > 0
                call todo#stack_push(block)
            endif
            let block = todo#block_new()
            let block = todo#block_append(block, line)
            " let block = [line]
            let indent = line.indent
        elseif line.indent < indent
            while len(stack) > 0
                let previous_block = todo#stack_pop()
                let previous_line = todo#block_get_head(previous_block)
                let block_line = todo#block_get_head(block)
                if previous_line.indent < block_line.indent
                    let previous_block = todo#block_append(previous_block, block)
                    let block = previous_block
                elseif previous_line.indent == block_line.indent
                    call todo#stack_push(previous_block)
                endif
            endwhile
            call todo#stack_push(block)
            let block = [line]
            let indent = line.indent
        else
            let block += [line]
        endif
        let linenr += 1
    endfor
    if len(block) > 0
        " let stack += block
        call todo#stack_push(block)
    endif

    echo s:stack
    return

    function! s:sort(line_dict)
        let changed = v:true
        while changed
            let changed = v:false
            let prev_linenr = -1
            for [linenr, struct] in items(a:line_dict)
                if prev_linenr != -1
                    let prev_struct = a:line_dict[prev_linenr]
                    let active_condition = (prev_struct.active < struct.active) || (prev_struct.active == struct.active)
                    let status_condition = struct.status < prev_struct.status 
                    if active_condition && status_condition
                        let tmp = a:line_dict[prev_linenr]
                        let a:line_dict[prev_linenr] = a:line_dict[linenr]
                        let a:line_dict[linenr] = tmp
                        let changed = v:true
                    endif
                endif
                let prev_linenr = linenr
            endfor
        endwhile
        return a:line_dict
    endfunction
    for [linenr, struct] in items(line_dict)
        call setline(linenr, struct.line)
    endfor
endfunction

function! todo#get_line_status(line)
    let complete = match(a:line, s:complete_regex) != -1
    let incomplete = match(a:line, s:incomplete_regex) != -1
    let partial = match(a:line, s:partial_regex) != -1
    let header = match(a:line, s:header_regex) != -1
    let comment = match(a:line, s:comment_regex) != -1

    if header || comment
        return -1
    elseif complete
        return 0
    elseif partial
        return 1
    elseif incomplete
        return 2
    else
        return 3
    endif
endfunction

" UTILITY FUNCTIONS

function! todo#init()
    if exists('s:todo_init')
        return
    endif
    let s:complete_regex   = '^\s*\[\((x)\|x\)\] - .*$'
    let s:partial_regex    = '^\s*\[\((/)\|/\)\] - .*$'
    let s:incomplete_regex = '^\s*\[\(( )\| \)\] - .*$'
    let s:active_regex     = '^\s*\[(\(x\|/\| \))\] - .*$'
    let s:header_regex     = '^/s*[^#[].*'
    let s:comment_regex    = '#.*'
    let s:todo_init = 1
endfunction

function! todo#get_indent_size()
    if &shiftwidth > 0 && &expandtab
        return &shiftwidth
    else
        return &tabstop
    endif
endfunction

function! todo#get_num_indents(line)
    " Empty line
    if match(a:line, '^\s*$') == 0
        return 0
    endif
    let indent_size = todo#get_indent_size()
    let indents = 0
    let index = 0
    while (match(a:line[index:index+indent_size-1], '\s\{' . indent_size . '\}') != -1)
        let index += indent_size
        let indents += 1
    endwhile

    return indents
endfunction

function! todo#stack_push(value)
    let s:stack += [a:value]
endfunction

function! todo#stack_pop()
    let v = s:stack[-1]
    let stack = s:stack[:-2]
    return v
endfunction

function! todo#test(...)
    if len(a:000) > 0
        for x in a:000
            echo x
        endfor
    else
        echo "No arguments"
    endif
endfunction
