" Create a new line below the current one with template task
function! todo#new_below()
    let cmd = g:todo_keymap['open_below'] . "[ ] - "
    call feedkeys(cmd, 'n')
endfunction

" Create a new line above the current one with template task
function! todo#new_above()
    let cmd = g:todo_keymap['open_above'] . "[ ] - "
    call feedkeys(cmd, 'n')
endfunction

" Create a template task if the current line only contains the word new.
" Used in combination with iabbrev command
function! todo#new_task()
    " If line only contains the word 'new'
    if match(getline('.'), '^\s*new$') == 0
        return "[ ] -"
    endif
    " Fallback to insert abbrev value
    return "new"
endfunction

" Create a template task below the current one if the current line has content
" not matching an empty task, otherwise clear the current content and
" move to the line below
function! todo#new_line()
    " If not at the end of line, return
    if !todo#util#eol()
        let cmd = g:todo_keymap['new_line']
        call feedkeys(cmd, 'n')
        return
    endif
    let line = getline('.')

    if match(line, '^\s*\[ \] -\s*$') == 0
        call setline('.', "")
        call feedkeys("\<CR>", 'n')
    else
        call feedkeys("\<ESC>", 'n')
        call todo#new_below()
    endif
endfunction

" Go to the next completion state if the current line matches a task
function! todo#toggle_completion() range
    for linenr in range(a:firstline, a:lastline)
        let linestring = getline(linenr)
        " Create a line object with the given string and linenr
        let line = todo#line#new(linestring, linenr)

        " If the current line isn't a task, continue
        if !todo#util#is_task(line.value)
            continue
        endif

        " Update the marker based on the map in g:todo_next_state
        let old_marker = copy(line.marker)
        call todo#marker#set_value(line.marker, g:todo_next_state.completion[line.marker.value])

        let new_line = line.value[0:old_marker.start-1] . line.marker.value . line.value[old_marker.end+1:]

        " Update the string value in the line object
        call todo#line#write(line, new_line)
        " Draw it onto the screen
        call todo#line#draw(line)
    endfor
endfunction

" Toggle the current line's status, next status is based on
" g:todo_next_state.status dictionary
function! todo#toggle_status()
    let linestring = getline('.')
    let linenr = line('.')
    " Create a line object with the given string and linenr
    let line = todo#line#new(linestring, linenr)

    " Return if not a task
    if !todo#util#is_task(line.value)
        return
    endif

    " Return if trying to make a closed task active
    if !line.status && line.kind ==? 'closed'
        return
    endif

    " Update the marker based on the map in g:todo_next_state
    let old_marker = copy(line.marker)
    call todo#marker#set_value(line.marker, g:todo_next_state.status[line.marker.value])

    let new_line = line.value[0:old_marker.start-1] . line.marker.value . line.value[old_marker.end+1:]

    " Update the string value in the line object
    call todo#line#write(line, new_line)
    " Draw it onto the screen
    call todo#line#draw(line)
endfunction

" Indent or outdent the range of lines given.
" Works in normal, visual and insert mode
" @indent: flag indicating to indent or outdent
" @mode: mode when executing function
function! todo#indent(indent, mode) range
    " If not at the end of line, fall back to normal behaviour
    if !todo#util#eol() && a:mode ==? 'i'
        let cmd = a:indent ? g:todo_keymap['indent'] : g:todo_keymap['outdent']
        call feedkeys(cmd, 'n')
        return
    endif
    let save_cursor = getcurpos()
    " If we are in insert mode, exit it
    if a:mode ==? 'i'
        call feedkeys("\<ESC>", 'n')
    endif
    " Set direction based on key pressed
    let dir = a:indent ? '>>' : '<<'
    for linenr in range(a:firstline, a:lastline)
        let cmd = linenr . 'gg' . dir
        call feedkeys(cmd, 'n')
    endfor
    call setpos('.', save_cursor)
    " If we are in insert mode, move to the end of line and enter insert mode
    if a:mode ==? 'i'
        call feedkeys("A", "n")
    endif
endfunction

function! todo#sort() range
    " Get the line contents and linenrs from the range given
    let linestrings = getline(a:firstline, a:lastline)
    let linenrs = range(a:firstline, a:lastline)

    " Initialize the stack and current block
    let line_blocks = []
    let lines_at_indent = []
    let indent = -1

    " Create line objects for each line in the range given
    for index in range(len(linenrs))
        " Convert the linestring and linenr to a line object
        let line = todo#line#new(linestrings[index], linenrs[index]) 

        if line.kind ==? 'empty'
            continue
        endif

        " Initialize if not done
        if indent == -1
            let indent = line.indent
        endif

        if line.indent > indent
            " Push block onto stack if it has content
            if !empty(lines_at_indent)
                call add(line_blocks, lines_at_indent)
            endif
            let lines_at_indent = []
            call add(lines_at_indent, line)

            " Create a new block and insert the current line
        elseif line.indent < indent
            call add(line_blocks, lines_at_indent)

            call todo#line#rearrange(line_blocks)

            let lines_at_indent = []
            call add(lines_at_indent, line)
        else
            " Insert line if their indents are equal
            call add(lines_at_indent, line)
        endif
        let indent = line.indent
    endfor
    if !empty(lines_at_indent)
        call add(line_blocks, lines_at_indent)
        call todo#line#rearrange(line_blocks)
    endif

    let l = line_blocks
    let line_blocks = []
    for ll in l
        call extend(line_blocks, ll)
    endfor
    
    call todo#line#sort(line_blocks)
    call todo#line#print(line_blocks)

    for line in line_blocks
        call todo#line#draw(line)
    endfor
endfunction
