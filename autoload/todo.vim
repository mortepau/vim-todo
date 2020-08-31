function! todo#new_below()
    call feedkeys("o[ ] - ", 'n')
endfunction

function! todo#new_above()
    call feedkeys("O[ ] - ", 'n')
endfunction

function! todo#toggle_completion()
    let linestring = getline('.')
    let linenr = line('.')
    let line = todo#line#new(linestring, linenr)

    if !todo#util#is_task(line.value)
        return
    endif

    " Update the marker based on the map in g:todo_completion_next_state
    let old_marker = copy(line.marker)
    call todo#marker#set_value(line.marker, g:todo_completion_next_state[line.marker.value])

    let new_line = line.value[0:old_marker.start-1] . line.marker.value . line.value[old_marker.end+1:]

    call todo#line#write(line, new_line)
    call todo#line#draw(line)
endfunction

function! todo#toggle_active()
    let linestring = getline('.')
    let linenr = line('.')
    let line = todo#line#new(linestring, linenr)

    " Return if not a task
    if !todo#util#is_task(line.value)
        return
    endif

    " Return if trying to make a complete task active
    if !line.status && g:todo_integer_to_completion[line.completion] ==? 'complete'
        return
    endif

    let old_marker = copy(line.marker)
    call todo#marker#set_value(line.marker, g:todo_active_next_state[line.marker.value])

    let new_line = line.value[0:old_marker.start-1] . line.marker.value . line.value[old_marker.end+1:]

    call todo#line#write(line, new_line)
    call todo#line#draw(line)
endfunction

function! todo#indent(indent)
    if a:indent
        call feedkeys('>>', 'n')
    else
        call feedkeys('<<', 'n')
    endif
endfunction

function! todo#sort() range
    echo "Sorting"
    return

"     let lines = getline(a:firstline, a:lastline)
"     let indent = todo#get_num_indents(lines[0])
"     let linenr = a:firstline
"     let s:stack = []
"     let block = todo#new_block()

"     for value in lines
"         " Ignore empty lines
"         if match(value, "^\s*$") != -1
"             let linenr += 1
"             continue
"         endif

"         let line = {
"             \ 'line': value,
"             \ 'linenr': linenr,
"             \ 'indent': todo#get_num_indents(value),
"             \ 'active': match(value, s:active_regex) != -1,
"             \ 'status': todo#get_line_status(value)
"         \ }

"         if line.indent > indent
"             if len(block) > 0
"                 call todo#stack_push(block)
"             endif
"             let block = todo#block_new()
"             let block = todo#block_append(block, line)
"             " let block = [line]
"             let indent = line.indent
"         elseif line.indent < indent
"             while len(stack) > 0
"                 let previous_block = todo#stack_pop()
"                 let previous_line = todo#block_get_head(previous_block)
"                 let block_line = todo#block_get_head(block)
"                 if previous_line.indent < block_line.indent
"                     let previous_block = todo#block_append(previous_block, block)
"                     let block = previous_block
"                 elseif previous_line.indent == block_line.indent
"                     call todo#stack_push(previous_block)
"                 endif
"             endwhile
"             call todo#stack_push(block)
"             let block = [line]
"             let indent = line.indent
"         else
"             let block += [line]
"         endif
"         let linenr += 1
"     endfor
"     if len(block) > 0
"         " let stack += block
"         call todo#stack_push(block)
"     endif

"     echo s:stack
"     return

"     function! s:sort(line_dict)
"         let changed = v:true
"         while changed
"             let changed = v:false
"             let prev_linenr = -1
"             for [linenr, struct] in items(a:line_dict)
"                 if prev_linenr != -1
"                     let prev_struct = a:line_dict[prev_linenr]
"                     let active_condition = (prev_struct.active < struct.active) || (prev_struct.active == struct.active)
"                     let status_condition = struct.status < prev_struct.status 
"                     if active_condition && status_condition
"                         let tmp = a:line_dict[prev_linenr]
"                         let a:line_dict[prev_linenr] = a:line_dict[linenr]
"                         let a:line_dict[linenr] = tmp
"                         let changed = v:true
"                     endif
"                 endif
"                 let prev_linenr = linenr
"             endfor
"         endwhile
"         return a:line_dict
"     endfunction
"     for [linenr, struct] in items(line_dict)
"         call setline(linenr, struct.line)
"     endfor
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
