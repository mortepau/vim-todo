" Create a new line below the current one with template task
function! todo#new_below() abort
    " Get the line the cursor is on
    let [err, current] = <SID>TodoTreeFindNode(line('.'))

    " Check if there was an error fetching the current line
    if err
        echoerr "vim-todo: Error inserting a new task below the current one"
    endif

    " Increase indent by one level if current line has children as the user
    " probably want to add a child task, otherwise use the same indent
    if current.num_children > 0
        let new_indent = (current.indent + 1) * shiftwidth()
    else
        let new_indent = current.indent * shiftwidth()
    endif

    " Create the template text with correct indentation
    let new_value = repeat(" ", new_indent) . g:todo_completion_templates.open

    let line = <SID>TodoTreeInsertAfter(new_value, current.linenr+1, current.parent)

    call append(line.linenr-1, line.value)
    call feedkeys(line.linenr .'ggA', 'n')
endfunction

" Create a new line above the current one with template task
function! todo#new_above() abort
    " Get the line the cursor is on
    let [err, current] = <SID>TodoTreeFindNode(line('.'))

    " Check if there was an error fetching the current line
    if err
        echoerr "vim-todo: Error inserting a new task above the current one"
    endif

    " Create a new template text with correct indentation
    let new_value = repeat(" ", current.indent * shiftwidth()) . g:todo_completion_templates.open

    let line = <SID>TodoTreeInsertBefore(new_value, current.linenr, current.parent)

    call append(line.linenr-1, line.value)
    call feedkeys(line.linenr . 'ggA', 'n')
endfunction

" Create a template task if the current line only contains the word in g:todo_inline_template
function! todo#new_task() abort
    " If line contains more than only the word in g:todo_inline_template
    if match(getline('.'), '^\s*' . g:todo_inline_template[0:-2] . '$') == -1
        call feedkeys(g:todo_inline_template[-1:-1], 'n')
        return
    endif

    let linenr = line('.')
    let indent = indent(linenr) / shiftwidth()
    let value = repeat(" ", indent * shiftwidth()) . g:todo_completion_templates.open

    " Find the parent based on indentation, if any
    let [err, parent] = <SID>TodoTreeFindParentFromIndent(linenr, indent)

    if err
        echoerr "vim-todo: Error finding parent"
    endif

    " Create a new line object and insert it after the current line
    let line = <SID>TodoTreeInsertAfter(value, linenr, parent)
    " Remove the existing line entry, but use linenr+1 since
    " TodoTreeInsertAfter increments each entry after the linenr of the
    " inserted entry.
    call <SID>TodoTreeRemoveNode(linenr+1, parent)

    call setline(line.linenr, line.value)
    call feedkeys("\<ESC>A", 'n')
endfunction

" Simulates the creation of a new line, has a few different behaviours
" depending on the current line and cursor position
" "  [ ] - some task  <- current string
" "11     23333333334 <- behaviour based on cursor position
" $1 Cursor anywhere in front of task template
"  -> open a new line above the current one with a task template
" $2 Cursor right after task template, but before any task text
"  -> open a new line above the current one with a task template
" $3 Cursor inside task text
"  -> Move text after cursor position to a new task on the line below
" $4 Cursor after task text
"  -> open a new line below the current one with a task template
"
" Another behaviour is when the current line contains only a task template
" and the line below is empty. In the example below ! is the current cursor
" position. Here it should remove the current line and create a new one below
" the current one.
" [ ] - text    -> [ ] - text
"   [ ] - !     ->
"               -> [ ] - !
function! todo#new_line()
    " Get the current line, with meta information
    let line = b:todo_tree.lines[line('.') - 1]

    " Find the start and end of the task template
    if line.kind !=? 'empty' && line.kind !=? 'other'
        let [string, start, end] = matchstrpos(line.value, "\\V" . g:todo_completion_templates[line.kind])
    else
        let start = 0
        let end = col('$')
    endif

    " Either before task template or right after task template, but before any task text
    if (col('.') <= start + 1 || col('.') == end + 1) && end + 1 < col('$')
        call feedkeys("\<ESC>", 'n')
        call todo#new_above()
    " Inside text
    elseif end <= col('.') && col('.') < col('$')
        let keep_text = line.value[0:col('.')-2]
        let move_text = line.value[col('.')-1:]
        let line.value = keep_text
        call feedkeys("\<ESC>", 'n')
        call todo#new_below()
        call feedkeys("\<ESC>", 'n')
        let newline = b:todo_tree.lines[line.linenr]
        let newline.value .= move_text
        call setline(line.linenr, line.value)
        call setline(newline.linenr, newline.value)
        call feedkeys(line.linenr . "ggA", 'n')
    " At the end of the line
    elseif col('.') == col('$')
        let curr_is_empty_template = match(line.value, "\\V\\^\\s\\*" . g:todo_completion_templates.open . "\\$") == 0
        let next_is_empty = match(getline(line.linenr+1), "^\s*$") == 0
        if col('$') == end+1 && curr_is_empty_template && next_is_empty
            let line.value = ""
            let line.indent = 0
            let line.kind = 'empty'
            let line.status = v:false
            let line.parent = -1
            let line.progress = 0
            call setline(line.linenr, line.value)
        endif

        call feedkeys("\<ESC>", 'n')
        call todo#new_below()
    endif

endfunction

" Converts the range of lines given by firstline and lastline into the correct
" template given by g:todo_completion_templates.
" Assumes the input string is in the form:
"   key "value" key "value"
" i.e. the string starts with a valid key and is followed by a value
" surrounded by quotes (""), this pattern repeats
function! todo#convert(string) range
    let valid_keys = ['open', 'closed']
    if g:todo_enable_partial_completion
        let valid_keys += ['partial']
    endif
    if g:todo_enable_active_status
        let valid_keys += ['active']
    endif

    let input_dict = {}

    " No input given, ask user for input instead
    if a:string =~? '^$'
        for key in valid_keys
            let answer = input("Enter template for '" . key . "': ")
            if answer !~? '^$'
                let input_dict[key] = answer
            endif
        endfor
    else
        let index = 0
        while index < len(a:string)
            " Find (key, value) pair
            let [key, kstart, kend] = matchstrpos(a:string, '"\?\s*\zs\S\+\ze\s*"', index)
            let [value, vstart, vend] = matchstrpos(a:string, '"\zs[^"]*\ze"', index)

            " Validate key
            if index(valid_keys, tolower(key)) != -1
                let input_dict[tolower(key)] = value
            else
                echoerr "vim-todo: Invalid key " . key
            endif

            " Update index
            if vstart != -1
                let index = vend+1
            else
                let index += 1
            endif
        endwhile
    endif

    for linenr in range(a:firstline, a:lastline)
        let changed = v:false
        let linestring = getline(linenr)
        for [key, value] in items(input_dict)
            let index = stridx(linestring, value)
            if index != -1
                let linestring = substitute(linestring, "\\V" . value, g:todo_completion_templates[key], "")
                let changed = v:true
            endif
        endfor
        if changed
            call setline(linenr, linestring)
        endif
    endfor
    doautocmd User TodoChange
endfunction

" Go to the next completion state if the current line matches a task
" open -> (partial)? -> closed -> open
function! todo#toggle_completion()
    " Get the line the cursor is on
    let [err, line] = <SID>TodoTreeFindNode(line('.'))

    " Check if there was an error fetching the current line
    if err
        echoerr "vim-todo: Error toggling completion of line " . line('.')
    endif

    " Do nothing if it is either empty or something other than a task
    if line.kind ==? 'empty' || line.kind ==? 'other'
        return
    endif

    " Find the new kind based on its current
    if line.kind ==? 'open'
        let key = 'open'
        let next = g:todo_enable_partial_completion ? 'partial' : 'closed'
    elseif line.kind ==? 'partial' && g:todo_enable_partial_completion
        let key = 'partial'
        let next = 'closed'
    else
        let key = 'closed'
        let next = 'open'
    endif

    " Find the start and end point of the current completion kind
    " Remove active status if the task is going to become closed
    if line.status && next ==? 'closed' && g:todo_enable_active_status
        let line.status = v:false
        let [string, start, end] = matchstrpos(line.value, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[key])
    else
        let [string, start, end] = matchstrpos(line.value, "\\V". g:todo_completion_templates[key])
    endif

    " Return if invalid starting point
    if start < 0
        return
    endif

    if start == 0
        let line.value = g:todo_completion_templates[next] . line.value[end:]
    else
        let line.value = line.value[0:start - 1] . g:todo_completion_templates[next] . line.value[end:]
    endif

    let line.kind = next
    " call todo#line#draw(line)
    call setline(line.linenr, line.value)

    if line.num_children > 0
        call <SID>update_children_completion(line.linenr)
    endif

    if line.parent != -1
        call <SID>update_parent_completion(line.linenr)
    endif
endfunction

" Toggle the current line's status
function! todo#toggle_status()
    if !g:todo_enable_active_status
        return
    endif

    " Get line object from b:todo_tree
    let line = b:todo_tree.lines[line('.') - 1]

    " Return if not a task
    if line.kind ==? 'empty' || line.kind ==? 'other'
        return
    endif

    " Return if trying to make a closed task active
    if !line.status && line.kind ==? 'closed'
        return
    endif

    if line.status
        let start_index = match(line.value, "\\V" . g:todo_completion_templates.active)
        if start_index == 0
            let line.value = line.value[1:]
        else
            let line.value = line.value[0:start_index-1] . line.value[start_index+1:]
        endif
    else
        if line.kind ==? 'open'
            let start_index = match(line.value, "\\V" . g:todo_completion_templates.open)
        elseif g:todo_enable_partial_completion && line.kind ==? 'partial'
            let start_index = match(line.value, "\\V" . g:todo_completion_templates.partial)
        elseif line.kind ==? 'closed'
            let start_index = match(line.value, "\\V" . g:todo_completion_templates.closed)
        endif

        if start_index < 0
            return
        endif

        if start_index == 0
            let line.value = g:todo_completion_templates.active . line.value
        else
            let line.value = line.value[0:start_index-1] . g:todo_completion_templates.active . line.value[start_index:]
        endif
    endif
    let line.status = !line.status

    " Draw it onto the screen
    call setline(line.linenr, line.value)
endfunction

" Indent or outdent the range of lines given.
" Works in normal and insert mode
" @mode: mode when executing function
function! todo#indent(mode, follow_parent)
    let save_cursor = getcurpos()

    " Exit insert mode if we are in it
    if a:mode ==? 'i'
        call feedkeys("\<ESC>", 'n')
    endif

    let [err, line] = <SID>TodoTreeFindNode(line('.'))

    if err
        echoerr "vim-todo: Error finding line " . line('.') . " while indenting"
        return
    endif

    " Move to line and indent
    call feedkeys(line.linenr . "gg>>", 'n')

    let line.indent += 1
    let line.value = repeat(" ", shiftwidth()) . line.value

    call <SID>TodoTreeUpdateHeritage(line, a:follow_parent)

    " Set cursor back to where it was when calling the function
    call setpos('.', save_cursor)

    " Re-enter insert mode if we were in it
    if a:mode ==? 'i'
        call feedkeys("A", 'n')
    endif
endfunction

" Wrapper around the function todo#line#sort().
" This finds which lines to sort based on firstline and lastline
" and builds a node structure of them before calling todo#line#sort().
" After finishing executing todo#line#sort(), redraw each line in the
" range with todo#line#draw().
function! todo#sort() range
    " Get the line contents and linenrs from the range given
    let linestrings = getline(a:firstline, a:lastline)
    let linenrs = range(a:firstline, a:lastline)

    " Build the node structure
    let lines = todo#line#build()
    
    " Sort the list in-place
    call todo#line#sort(lines)

    " Redraw them
    for line in lines
        call todo#line#draw(line)
    endfor
endfunction

function! todo#initialize()
    let b:todo_tree = {}
    let b:todo_tree.namespace = nvim_create_namespace('vim-todo')
    let b:todo_tree.virtual_text = []
    let b:todo_tree.lines = []
    let buffer_lines = getline(1, line('$'))
    let buffer_linenrs = range(1, line('$'))
    for linenr in buffer_linenrs
        let b:todo_tree.lines += [todo#line#new(buffer_lines[linenr-1], linenr)]
        let b:todo_tree.virtual_text += [[[], [], []]]
    endfor
    let b:todo_tree.nodes = todo#line#build(b:todo_tree.lines)

    let b:todo_tree.display_virtual_text = g:todo_enable_virtual_text

    if g:todo_enable_virtual_text
        call <SID>read_dates()
        call <SID>update_virtual_text()
        call <SID>set_virtual_text()
    endif
endfunction

" Recreate the node tree and the List of lines
" Used to refresh broken structures
function! todo#refresh()
    let b:todo_tree.lines = []
    let buffer_lines = getline(1, '$')
    let buffer_linenrs = range(1, line('$'))
    for linenr in buffer_linenrs
        let b:todo_tree.lines += [todo#line#new(buffer_lines[linenr-1], linenr)]
    endfor
    let b:todo_tree.nodes = todo#line#build(b:todo_tree.lines)
endfunction

" Update to tree from an internal event
function! todo#change()
    echom "Todo change"
    if g:todo_enable_virtual_text
        call <SID>update_virtual_text()
        call <SID>set_virtual_text()
    endif
endfunction

" Update to tree from an external event
function! todo#update()
    echom "Todo Update"
    return
    let buffer_lines = getline(1, line('$'))
    let buffer_linenrs = range(1, line('$'))
    let b:todo_tree.nodes = todo#line#build()
    let b:todo_tree.lines = []
    for linenr in buffer_linenrs
        let b:todo_tree.lines += [todo#line#new(buffer_lines[linenr-1], linenr)]
    endfor

    if g:todo_enable_virtual_text
        call <SID>update_virtual_text()
        call <SID>set_virtual_text()
    endif
endfunction

function! todo#show_virtual_text()
    if g:todo_enable_virtual_text
        let b:todo_tree.display_virtual_text = v:true
        call <SID>set_virtual_text()
    endif
endfunction

function! todo#hide_virtual_text()
    if g:todo_enable_virtual_text
        let b:todo_tree.display_virtual_text = v:false
        call nvim_buf_clear_namespace(0, b:todo_tree.namespace, 0, -1)
    endif
endfunction

function! s:read_dates()
    return
endfunction

function! s:update_virtual_text()
    echom "Update virtual text"
    call <SID>update_creation_dates()
    call <SID>update_update_dates()
    call <SID>update_percentage_completion()
endfunction

function! s:update_creation_dates()
    return
endfunction

function! s:update_update_dates()
    return
endfunction

function! s:update_percentage_completion()
    function! s:iterate(lines)
        let progress = 0
        for line in a:lines
            if line.kind ==? 'empty' || line.kind ==? 'other'
                continue
            endif
            if line.num_children > 0
                let p = <SID>iterate(line.children)
            else
                if line.kind ==? 'open'
                    let p = 0
                elseif g:todo_enable_partial_completion && line.kind ==? 'partial'
                    let p = 50
                else
                    let p = 100
                endif
            endif
            let text = "(" . p. "%) "
            if p < 50
                let hl = 'TodoRed'
            elseif p < 80
                let hl = 'TodoYellow'
            else
                let hl = 'TodoGreen'
            endif

            let b:todo_tree.virtual_text[line.linenr - 1][0] = [text, hl]
            let progress += p
            let line.progress = p
        endfor
        let progress /= len(a:lines)
        return progress
    endfunction

    call <SID>iterate(b:todo_tree.nodes)
endfunction

function! s:set_virtual_text()
    if !b:todo_tree.display_virtual_text
        return
    endif
    for linenr in range(1, line('$'))
        let [pc, cd, ud] = b:todo_tree.virtual_text[linenr-1]
        let chunks = []
        if g:todo_enable_percentage_completion && !empty(pc)
            let chunks += [pc]
        endif
        if g:todo_enable_creation_date && !empty(cd)
            let chunks += [cd]
        endif
        if g:todo_enable_update_date && !empty(ud)
            let chunks += [ud]
        endif
        if !empty(chunks)
            call nvim_buf_set_virtual_text(0, b:todo_tree.namespace, linenr-1, chunks, [])
        endif
    endfor
endfunction

function! s:update_children_completion(linenr)
    let [err, parent] = <SID>TodoTreeFindNode(a:linenr)

    if err
        echoerr "vim-todo: Error updating children after completion"
    endif

    for child in parent.children
        if child.kind ==? parent.kind
            continue
        endif

        if child.status && parent.kind ==? 'closed' && g:todo_enable_active_status
            let [string, start, end] = matchstrpos(child.value, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[child.kind])
        else
            let [string, start, end] = matchstrpos(child.value, "\\V" . g:todo_completion_templates[child.kind])
        endif

        if start < 0
            continue
        endif

        if start == 0
            let child.value = g:todo_completion_templates[parent.kind] . child.value[end:]
        else
            let child.value = child.value[0:start - 1] . g:todo_completion_templates[parent.kind] . child.value[end:]
        endif

        let child.kind = parent.kind
        
        call setline(child.linenr, child.value)

        if child.num_children > 0
            call <SID>update_children_completion(child.linenr)
        endif
    endfor
endfunction

function! s:update_parent_completion(linenr) abort
    let [err, child] = <SID>TodoTreeFindNode(a:linenr)

    if err
        echoerr "vim-todo: Error finding child when updating parent after completion"
    endif

    let [err, parent] = <SID>TodoTreeFindNode(child.parent)

    if err
        echoerr "vim-todo: Error finding parent when updating parent after completion"
    endif

    let all_equal = v:true
    if parent.num_children > 1
        for c in parent.children
            if c.kind !=? child.kind && c.kind !=? 'empty' && c.kind !=? 'other'
                let all_equal = v:false
            endif
        endfor
    endif

    if parent.num_children == 1 || (all_equal && child.kind ==? 'closed') || (!all_equal && child.kind ==? 'open')
        if parent.kind ==? child.kind
            return
        endif

        if parent.status && child.kind ==? 'closed' && g:todo_enable_active_status
            let [string, start, end] = matchstrpos(parent.value, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[parent.kind])
        else
            let [string, start, end] = matchstrpos(parent.value, "\\V" . g:todo_completion_templates[parent.kind])
        endif

        if start < 0
            return
        endif

        if start == 0
            let parent.value = g:todo_completion_templates[child.kind] . parent.value[end:]
        else
            let parent.value = parent.value[0:start - 1] . g:todo_completion_templates[child.kind] . parent.value[end:]
        endif

        let parent.kind = child.kind
        call setline(parent.linenr, parent.value)
    endif

    if parent.parent != -1
        call <SID>update_parent_completion(parent.linenr)
    endif
endfunction

" HELPER FUNCTIONS

function! s:TodoTreeFindNode(linenr)
    if len(b:todo_tree.lines) < a:linenr || a:linenr < 1
        return [1, todo#line#new("", -1)]
    endif
    return [0, b:todo_tree.lines[a:linenr-1]]
endfunction

function Parent(linenr)
    return <SID>TodoTreeFindParent(a:linenr)
endfunction

function! s:TodoTreeFindParentFromIndent(linenr, indent)
    " Zero indentation  or top line cannot have a parent
    if a:indent == 0 || a:linenr == 1
        return [0, -1]
    endif

    let linenr = a:linenr

    while linenr != 0
        let linenr -= 1

        let [err, parent] = <SID>TodoTreeFindNode(linenr)

        if err
            echoerr "vim-todo: Error finding parent based on indentation"
        endif

        if parent.indent < a:indent
            return [0, parent.linenr]
        endif
    endwhile
    return [1, 0]
endfunction

function! s:TodoTreeFindParent(linenr)
    let [err, self] = <SID>TodoTreeFindNode(a:linenr)

    " Error finding line at linenr
    if err
        return [1, 0]
    endif

    " Zero indent or top line cannot have a parent
    if self.indent == 0 || self.linenr == 1
        return [0, -1]
    endif

    let linenr = self.linenr
    while linenr > 0
        let linenr -= 1

        let [err, potential_parent] = <SID>TodoTreeFindNode(linenr)

        if err
            return [1, 0]
        endif

        if potential_parent.indent < self.indent
            return [0, potential_parent.linenr]
        endif
    endwhile
    return [1, 0]
endfunction

function! s:TodoTreeInsertBefore(value, linenr, parent)
    let line = todo#line#new(a:value, a:linenr)
    let line.parent = a:parent

    " Insert the new line into the ordered list
    call insert(b:todo_tree.lines, line, line.linenr - 1)

    " Update the parent of the new line
    if a:parent != -1
        let parent = b:todo_tree.lines[a:parent-1]
        let i = 0
        while parent.children[i].linenr != line('.')
            let i += 1
        endwhile
        call insert(parent.children, line, i)
        let parent.num_children += 1
    endif

    " Update the linenr of all lines after the new one
    for l in b:todo_tree.lines[line.linenr:]
        let l.linenr += 1
        if line.linenr < l.parent
            let l.parent += 1
        endif
    endfor

    return line
endfunction

function! s:TodoTreeInsertAfter(value, linenr, parent)
    let line = todo#line#new(a:value, a:linenr)
    let line.parent = a:parent

    " Insert the new line into the ordered list
    call insert(b:todo_tree.lines, line, line.linenr - 1)

    " Update the parent of the new line
    if a:parent != -1
        let parent = b:todo_tree.lines[a:parent-1]
        let i = 0
        while parent.children[i].linenr != line('.')
            let i += 1
        endwhile
        call insert(parent.children, line, i+1)
        let parent.num_children += 1
    endif

    " Update the linenr of all lines after the new one
    for l in b:todo_tree.lines[line.linenr:]
        let l.linenr += 1
        if line.linenr < l.parent
            let l.parent += 1
        endif
    endfor

    return line
endfunction

function! s:TodoTreeInsertChild(parent, child)
    let i = 0
    while i < a:parent.num_children && a:parent.children[i] < a:child.linenr
        let i += 1
    endwhile
    call insert(a:parent.children, a:child, i)
    let a:parent.num_children += 1
    let a:child.parent = a:parent.linenr
endfunction

function! s:TodoTreeRemoveNode(linenr, parent_linenr)
    if a:parent_linenr != -1
        call filter(b:todo_tree.lines[a:parent_linenr-1].children, "v:val.linenr != " . string(a:linenr))
        let b:todo_tree.lines[a:parent_linenr-1].num_children -= 1
    endif
    call filter(b:todo_tree.lines, "v:val.linenr != " . string(a:linenr))
    return
endfunction

" 0      0      0
"  1      1      1
"  1      1      1
"   2      2      2
"
" 0      0      0
"  1     1       1
"  1      1     1
"  2       2      2
function! s:TodoTreeUpdateHeritage(line, follow_parent) abort
    let [err, new_parent] = <SID>TodoTreeFindParent(a:line.linenr)

    if err
        echoerr "vim-todo: Error could not update heritage, no parent found"
    endif

    let [err, parent_node] = <SID>TodoTreeFindNode(new_parent) 

    if err
        echoerr "vim-todo: Error could not find parent node"
    endif

    " Remove the line from the old parent's children List
    if a:line.parent != -1
        let [err, old_parent] = <SID>TodoTreeFindNode(a:line.parent)

        if err
            echoerr "vim-todo: Error finding parent node"
        endif

        let old_parent.num_children -= 1
        call filter(old_parent.children, "v:val.linenr != " . string(a:line.linenr))
    endif


    " Insert the line into the new parent's children List
    call <SID>TodoTreeInsertChild(parent_node, a:line)

    if a:line.num_children != 0
        for child in a:line.children
            let [err, parent] = <SID>TodoTreeFindParent(child.linenr)

            if err
                echoerr "vim-todo: Error finding parent of child"
                continue
            endif

            let child.parent = parent
        endfor
        call filter(a:line.children, "v:val.parent == " . string(a:line.linenr))
    endif
endfunction

function! s:TodoTreeValidIndentation(linenr)
    let [err, self] = <SID>TodoTreeFindNode(a:linenr)
    
    if err
        echoerr "vim-todo: Error finding line"
    endif

    let linenr = a:linenr
    while linenr != 0
        let linenr -= 1

        let [err, potential_parent] = <SID>TodoTreeFindNode(linenr)

        if err
            return v:false
        endif

        let difference = self.indent - potential_parent.indent
        if difference == 1
            return v:true
        elseif difference > 1
            return v:false
        endif
    endwhile
endfunction

function PRINT(linenr)
    let line = b:todo_tree.lines[a:linenr-1]
    echom "{'linenr': " . line.linenr . ", 'status': " . line.status . ", 'parent': " . line.parent . ", 'children': [], 'indent': " . line.indent . ", 'num_children': " . line.num_children . ", '__struct__': '" . line.__struct__ . "', 'kind': '" . line.kind . "', 'value': '" . line.value . "', progress: " . line.progress . "}"
    for l in line.children
        echom l
    endfor
endfunction

"
" Keybindings
" <CR> (insert) : Insert line (below, above) current one depending on cursor position
" <CR> (normal) : Toggle completion
" <TAB> (insert) : Indent line (and children)
" <TAB> (normal) : Indent line (and children)
" <S-TAB> (insert) : Deindent line (and children)
" <S-TAB> (normal) : Deindent line (and children)
" <SPACE> (normal) : Toggle active status
" o (normal) : Insert line below current one
" O (normal) : Insert line above current one
"
" Commands
" TodoConvert - Convert to valid templates
" TodoSort - Sort based on criteria
" TodoShow - Display virtual text
" TodoHide - Hide virtual text
