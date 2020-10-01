if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

" TODO: Fix cchar in syntax file
" TODO: Fix update time

" Options {{{

setlocal shiftwidth=2
setlocal softtabstop=2
setlocal cursorline
setlocal expandtab
setlocal noautoindent
setlocal concealcursor=nv
setlocal conceallevel=2

" }}}

" Header movement {{{

function! s:TodoHeaderNext()
    let lnum = line('.')

    let potential_header = lnum
    while potential_header < line('$')
        let potential_header += 1

        if indent(potential_header) == 0 && <SID>TodoLineIsTask(potential_header)
            call cursor(potential_header, 1)
            return
        endif
    endwhile

    let potential_header = 0
    while potential_header < lnum-1
        let potential_header += 1

        if indent(potential_header) == 0 && <SID>TodoLineIsTask(potential_header)
            call cursor(potential_header, 1)
            return
        endif
    endwhile
endfunction

function! s:TodoHeaderPrev()
    let lnum = line('.')

    let potential_header = lnum
    while potential_header > 0
        let potential_header -= 1

        if indent(potential_header) == 0 && <SID>TodoLineIsTask(potential_header)
            call cursor(potential_header, 1)
            return
        endif
    endwhile

    let potential_header = line('$')
    while potential_header > lnum+1
        let potential_header -= 1

        if indent(potential_header) == 0 && <SID>TodoLineIsTask(potential_header)
            call cursor(potential_header, 1)
            return
        endif
    endwhile
endfunction

" }}}

" Task editing {{{

function! s:TodoNewTask()
    let lnum = line('.')
    let self = getline('.')
    let self_kind = <SID>TodoFindKind(lnum)

    let cursor = col('.')

    if self_kind ==? 'empty'
        let tick_start  = cursor - 2
        let tick_end    = cursor
        let text_start  = cursor - 2
        let text_end    = cursor - 1
        let cdate_start = -1
        let cdate_end   = -1
        let udate_start = -1
        let udate_end   = -1

        call setline(lnum, "")
    else
        let [_, tick_start, tick_end]   = matchstrpos(self, "\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates[self_kind])
        let [_, cdate_start, cdate_end] = matchstrpos(self, "\\V" . <SID>TodoEscapeDate(g:todo_date_templates.creation))
        let [_, udate_start, udate_end] = matchstrpos(self, "\\V" . <SID>TodoEscapeDate(g:todo_date_templates.update))

        let text_start = tick_end
        if cdate_start == -1 && udate_start == -1
            let text_end = col('$')
        elseif cdate_start == -1
            let text_end = match(self, "\\V\\s\\{-\\}" . <SID>TodoEscapeDate(g:todo_date_templates.update) . "\\$")
        else
            let text_end = match(self, "\\V\\s\\{-\\}" . <SID>TodoEscapeDate(g:todo_date_templates.creation) . "\\$")
        endif
    endif

    if text_end < text_start
        let text_end = text_start
    endif

    call feedkeys("\<ESC>", 'n')
    if cursor <= tick_start + 1
        call <SID>TodoOpenTaskAbove()
    elseif tick_end < cursor && cursor <= text_end
        let keep = self[0:cursor-2] . self[text_end:]
        let move = repeat(" ", indent(lnum)) . g:todo_completion_templates.open . self[cursor-1:text_end-1]
        let move = <SID>TodoLineAppendCreationDate(move)
        let move = <SID>TodoLineAppendUpdateDate(move)
        call setline(lnum, keep)
        call append(lnum, move)
        call cursor(lnum, cursor)
    elseif cursor == text_end + 1
        let curr_line_only_tick = tick_end == text_end
        let next_line_empty = <SID>TodoLineIsEmpty(lnum+1)
        if curr_line_only_tick && next_line_empty
            call setline(lnum, "")
        endif
        call <SID>TodoOpenTaskBelow()
    endif

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

function! s:TodoNewTaskInline()
    let lnum = line('.')

    if match(getline('.'), '^\s*' . g:todo_inline_template[0:-2] . '\s*$') == -1
        call feedkeys(g:todo_inline_template[-1:-1], 'n')
        return
    endif

    let new_value = repeat(" ", indent(lnum)) . g:todo_completion_templates.open

    let new_value = <SID>TodoLineAppendCreationDate(new_value)
    let new_value = <SID>TodoLineAppendUpdateDate(new_value)

    call setline(lnum, new_value)
    call feedkeys("\<ESC>", 'n')
    call feedkeys("A", 'm')

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

function! s:TodoOpenTaskBelow()
    let lnum = line('.')

    if <SID>TodoLineIsParent(lnum) || (indent(lnum) == 0 && !<SID>TodoLineIsEmpty(lnum))
        let new_indent = indent(lnum) + shiftwidth()
    else
        let new_indent = indent(lnum)
    endif
    let new_value = repeat(" ", new_indent) . g:todo_completion_templates.open

    let new_value = <SID>TodoLineAppendCreationDate(new_value)
    let new_value = <SID>TodoLineAppendUpdateDate(new_value)

    call append(lnum, new_value)

    if g:todo_auto_update_tasks
        call <SID>TodoLineUpdateParentCompletion(lnum+1)
    endif

    call feedkeys(lnum+1 . 'ggA', 'm')

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

function! s:TodoOpenTaskAbove()
    let lnum = line('.')

    let new_indent = indent(lnum)
    let new_value = repeat(" ", new_indent) . g:todo_completion_templates.open

    let new_value = <SID>TodoLineAppendCreationDate(new_value)
    let new_value = <SID>TodoLineAppendUpdateDate(new_value)

    call append(lnum-1, new_value)

    if g:todo_auto_update_tasks
        call <SID>TodoLineUpdateParentCompletion(lnum)
    endif

    call feedkeys(lnum . "gg", 'n')
    call feedkeys('A', 'm')

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

" }}}

" Insert and Append {{{

function! s:TodoInsert()
    let lnum = line('.')
    if !<SID>TodoLineIsTask(lnum)
        call feedkeys("I", 'n') 
        return
    else
        let kind = <SID>TodoFindKind(lnum)
        if <SID>TodoLineIsActive(lnum) && g:todo_enable_active_status
            let [_, start, end] = matchstrpos(getline('.'), "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[kind])
        else
            let [_, start, end] = matchstrpos(getline('.'), "\\V" . g:todo_completion_templates[kind])
        endif
        call cursor(lnum, end)
        call feedkeys("a", 'n')
    endif
endfunction

function! s:TodoAppend()
    let lnum = line('.')
    if !<SID>TodoLineIsTask(lnum)
        call feedkeys("A", 'n')
        return
    elseif g:todo_enable_creation_date || g:todo_enable_update_date
        let kind = <SID>TodoFindKind(lnum)
        if <SID>TodoLineIsTemplate(lnum)
            let end = matchend(getline(lnum), "\\V" . g:todo_completion_templates[kind])
            call cursor(lnum, end+1)
            call feedkeys("i", 'n')
        else
            let dates = "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.creation) . "\\)\\?\\(" . <SID>TodoEscapeDate(g:todo_date_templates.update) . "\\)\\?"
            let start = match(getline(lnum), "\\V\\S\\zs\\s\\*" . dates . "\\$")
            call cursor(lnum, start+1)
            call feedkeys("i", 'n')
        endif
    else
        call feedkeys("A", 'n')
    endif
endfunction

" }}}

" Task status {{{

function! s:TodoToggleCompletion()
    let lnum = line('.')
    let curr_value = getline('.')
    if !<SID>TodoLineIsTask(lnum)
        return
    endif

    if <SID>TodoLineIsOpen(lnum)
        let key = 'open'
        let next = g:todo_enable_partial_completion ? 'partial' : 'closed'
    elseif <SID>TodoLineIsPartial(lnum)
        let key = 'partial'
        let next = 'closed'
    else
        let key = 'closed'
        let next = 'open'
    endif

    if <SID>TodoLineIsActive(lnum) && next ==? 'closed' && g:todo_enable_active_status
        let [_, start, end] = matchstrpos(curr_value, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[key])
    else
        let [_, start, end] = matchstrpos(curr_value, "\\V". g:todo_completion_templates[key])
    endif

    if start < 0
        return
    endif

    if start == 0
        let curr_value = g:todo_completion_templates[next] . curr_value[end:]
    else
        let curr_value = curr_value[0:start-1] . g:todo_completion_templates[next] . curr_value[end:]
    endif

    call setline(lnum, curr_value)

    if <SID>TodoLineIsParent(lnum) && g:todo_auto_update_tasks
        call <SID>TodoLineUpdateChildrenCompletion(lnum)
    endif

    if <SID>TodoFindParent(lnum) && g:todo_auto_update_tasks
        call <SID>TodoLineUpdateParentCompletion(lnum)
    endif

    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

function! s:TodoToggleActive()
    if !g:todo_enable_active_status
        return
    endif

    let lnum = line('.')
    let self = getline('.')
    let self_kind = <SID>TodoFindKind(lnum)

    if !<SID>TodoLineIsTask(lnum)
        return
    endif

    if !<SID>TodoLineIsActive(lnum) && self_kind ==? 'closed'
        return
    endif

    if <SID>TodoLineIsActive(lnum)
        let start = match(self, "\\V" . g:todo_completion_templates.active)
        if start
            let self = self[0:start-1] . self[start+1:]
        else
            let self = self[1:]
        endif
    else
        if self_kind ==? 'open'
            let start = match(self, "\\V" . g:todo_completion_templates.open)
        elseif g:todo_enable_partial_completion && self_kind ==? 'partial'
            let start = match(self, "\\V" . g:todo_completion_templates.partial)
        elseif self_kind ==? 'closed'
            let start = match(self, "\\V" . g:todo_completion_templates.closed)
        endif

        if start < 0
            return
        endif

        if start
            let self = self[0:start-1] . g:todo_completion_templates.active . self[start:]
        else
            let self = g:todo_completion_templates.active . self
        endif
    endif

    call setline(lnum, self)
endfunction

" }}}

" Indentation {{{

function! s:TodoIndent(mode, follow)
    let save_cursor = getpos('.')

    if a:mode ==? 'i'
        call feedkeys("\<ESC>", 'n')
    endif

    let lnum = line('.')

    if a:follow
        function! s:indent(lnum)
            for child in <SID>TodoFindChildren(a:lnum)
                call <SID>indent(child)
            endfor
            call feedkeys(a:lnum . "gg>>", 'nx')
        endfunction

        for child in <SID>TodoFindChildren(lnum)
            call <SID>indent(child)
        endfor
    endif

    call feedkeys(lnum . "gg>>", 'nx')

    if g:todo_auto_update_tasks
        call <SID>TodoLineUpdateParentCompletion(lnum)
    endif

    " Indent the cursor position as well
    let save_cursor[2] += shiftwidth()
    call setpos('.', save_cursor)

    if a:mode ==? 'i'
        call feedkeys("\<ESC>", 'n')
        call feedkeys("a", 'm')
    endif

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

function! s:TodoDeindent(mode, follow)
    let lnum = line('.')

    if indent(lnum) == 0
        return
    endif

    let save_cursor = getpos('.')

    let parent = <SID>TodoFindParent(lnum)

    if a:mode ==? 'i'
        call feedkeys("\<ESC>", 'n')
    endif

    if a:follow
        function! s:deindent(lnum)
            for child in <SID>TodoFindChildren(a:lnum)
                call <SID>deindent(child)
            endfor
            call feedkeys(a:lnum . "gg<<", 'nx')
        endfunction

        for child in <SID>TodoFindChildren(lnum)
            call <SID>deindent(child)
        endfor
    endif

    call feedkeys(lnum . "gg<<", 'nx')

    if g:todo_auto_update_tasks
        call <SID>TodoLineUpdateParentCompletion(lnum)
        if parent
            for children in <SID>TodoFindChildren(parent)
                call <SID>TodoLineUpdateParentCompletion(children)
            endfor
        endif
    endif

    if save_cursor[2] < shiftwidth() + 1
        let save_cursor[2] = 0
    else
        let save_cursor[2] -= shiftwidth()
    endif
    call setpos('.', save_cursor)

    if a:mode ==? 'i'
        call feedkeys("\<ESC>", 'n')
        call feedkeys("a", 'm')
    endif

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

" }}}

" Command functions {{{

function! s:TodoConvert(string)
    let valid_keys = ['open', 'partial', 'closed', 'active']
    let input_dict = {}

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
            let [key, kstart, kend] = matchstrpos(a:string, '"\?\s*\zs\S\+\ze\s*"', index)
            let [value, vstart, vend] = matchstrpos(a:string, '"\zs[^"]*\ze"', index)

            if index(valid_keys, tolower(key)) != -1
                let input_dict[tolower(key)] = value
            else
                echoerr "vim-todo: Invalid key '" . key . "'"
            endif

            if vstart != -1
                let index = vend+1
            else
                let index += 1
            endif
        endwhile
    endif

    for linenr in range(1, line('$'))
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

    if g:todo_enable_orphan_highlight
        call <SID>TodoSetOrphanStatus()
    endif
    if g:todo_enable_virtual_text
        call <SID>TodoShow()
    endif
endfunction

function! s:TodoShow()
    call <SID>TodoHide()
    if g:todo_enable_virtual_text
        call <SID>TodoSetVirtualPercentage()
    endif
endfunction

function! s:TodoHide()
    if g:todo_enable_virtual_text && exists('b:todo_ns_vt')
        call nvim_buf_clear_namespace(0, b:todo_ns_vt, 0, -1)
    endif
endfunction

function! s:TodoSort()
endfunction

function! s:TodoSortBlock()
endfunction

" }}}

" Virtual text & match {{{

function! s:TodoSetOrphanStatus()
    let orphans = TodoFindOrphans()
    if exists('b:TodoOrphans')
        call matchdelete(b:TodoOrphans)
        unlet b:TodoOrphans
    endif
    if empty(orphans)
        return
    else
        let b:TodoOrphans = matchaddpos("Error", orphans)
    endif
endfunction

function! s:TodoSetVirtualPercentage()
    let headers = []
    " Iterate over all lines and find the headers
    for linenr in range(1, line('$'))
        if <SID>TodoLineIsTask(linenr) && indent(linenr) / shiftwidth() == 0
            call add(headers, linenr)
        endif
    endfor

    for header in headers
        call <SID>TodoLineSetVirtualPercentage(header)
    endfor
endfunction

function! s:TodoLineSetVirtualPercentage(linenr)
    if !<SID>TodoLineIsTask(a:linenr)
        return 0
    endif

    if <SID>TodoLineIsParent(a:linenr)
        let percentage = 0
        let children = <SID>TodoFindChildren(a:linenr)
        for child in children
            let percentage += <SID>TodoLineSetVirtualPercentage(child)
        endfor
        let percentage /= len(children)
    else
        if <SID>TodoLineIsOpen(a:linenr)
            let percentage = 0
        elseif <SID>TodoLineIsPartial(a:linenr)
            let percentage = 50
        else
            let percentage = 100
        endif
    endif

    let percentage_vt_string = "(" . string(percentage) . "%)"
    if percentage < 33
        let percentage_hl_group = "TodoRed"
    elseif percentage < 66
        let percentage_hl_group = "TodoYellow"
    else
        let percentage_hl_group = "TodoGreen"
    endif

    if <SID>TodoLineIsTask(a:linenr)
        call <SID>TodoLineSetVirtualComponent(a:linenr, 'percentage', percentage_vt_string, percentage_hl_group)
    endif

    return percentage
endfunction

function! s:TodoLineSetVirtualComponent(linenr, component, string, hl_group)
    let chunks = nvim_buf_get_virtual_text(0, a:linenr-1)

    if empty(chunks)
        let chunks = [["", ""], ["", ""], ["", ""]]
    endif

    if a:component ==? 'percentage'
        let chunks[0] = [a:string, a:hl_group]
    elseif a:component ==? 'creation'
        let chunks[1] = [a:string, a:hl_group]
    elseif a:component ==? 'update'
        let chunks[2] = [a:string, a:hl_group]
    endif

    if !exists('b:todo_ns_vt')
        let b:todo_ns_vt = nvim_create_namespace('TodoVirtualText')
    endif
    call nvim_buf_set_virtual_text(0, b:todo_ns_vt, a:linenr-1, chunks, [])
endfunction

" }}}

" Update hierarchy {{{

function! s:TodoLineUpdateParentCompletion(linenr)
    let parent = <SID>TodoFindParent(a:linenr)

    if !parent
        return
    endif

    let self_kind = <SID>TodoFindKind(a:linenr)
    let parent_value = getline(parent)
    let parent_kind = <SID>TodoFindKind(parent)
    let children = <SID>TodoFindChildren(parent)

    let all_equal = v:true
    if !empty(children)
        for child in children
            let child_kind = <SID>TodoFindKind(child)
            if self_kind !=? child_kind && child_kind !=? 'empty' && child_kind !=? 'other'
                let all_equal = v:false
            endif
        endfor
    endif

    if len(children) == 1 || (all_equal && self_kind ==? 'closed') || (!all_equal && self_kind ==? 'open')
        if parent_kind ==? self_kind
            return
        endif
        
        if <SID>TodoLineIsActive(parent) && self_kind ==? 'closed' && g:todo_enable_active_status
            let [_, start, end] = matchstrpos(parent_value, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[parent_kind])
        else
            let [_, start, end] = matchstrpos(parent_value, "\\V" . g:todo_completion_templates[parent_kind])
        endif

        if start < 0
            return
        endif

        if start == 0
            let parent_value = g:todo_completion_templates[self_kind] . parent_value[end:]
        else
            let parent_value = parent_value[0:start - 1] . g:todo_completion_templates[self_kind] . parent_value[end:]
        endif

        call setline(parent, parent_value)
    endif

    if <SID>TodoFindParent(parent)
        call <SID>TodoLineUpdateParentCompletion(parent)
    endif
endfunction

function! s:TodoLineUpdateChildrenCompletion(linenr)
    let parent_kind = <SID>TodoFindKind(a:linenr)
    let children = <SID>TodoFindChildren(a:linenr)
    for child in children
        let child_kind = <SID>TodoFindKind(child)
        if parent_kind ==? child_kind
            continue
        endif

        let child_value = getline(child)

        if <SID>TodoLineIsActive(child) && parent_kind ==? 'closed' && g:todo_enable_active_status
            let [_, start, end] = matchstrpos(child_value, "\\V" . g:todo_completion_templates.active . g:todo_completion_templates[child_kind])
        else
            let [_, start, end] = matchstrpos(child_value, "\\V" . g:todo_completion_templates[child_kind])
        endif

        if start < 0
            continue
        endif

        if start == 0
            let child_value = g:todo_completion_templates[parent_kind] . child_value[end:]
        else
            let child_value = child_value[0:start-1] . g:todo_completion_templates[parent_kind] . child_value[end:]
        endif

        call setline(child, child_value)

        if <SID>TodoLineIsParent(child)
            call <SID>TodoLineUpdateChildrenCompletion(child)
        endif
    endfor
endfunction

" }}}

" Find {{{

function! s:TodoFindParent(linenr)
    if a:linenr < 1 || a:linenr > line('$')
        return 0
    endif

    let curr_indent = indent(a:linenr) / shiftwidth()

    let lnum = a:linenr
    let indents = []
    while lnum > 0
        if <SID>TodoLineIsEmpty(lnum)
            return 0
        endif

        let parent_indent = indent(lnum) / shiftwidth()
        call add(indents, curr_indent - parent_indent)
        if curr_indent - parent_indent == 1
            let n = max(indents)
            if n > 1
                return 0
            else
                return lnum
            endif
        endif
        let lnum -= 1
    endwhile
    return 0
endfunction

function! s:TodoFindChildren(linenr)
    if !<SID>TodoLineIsParent(a:linenr)
        return []
    endif

    let curr_indent = indent(a:linenr) / shiftwidth()
    let lnum = a:linenr+1

    let children = []
    while lnum <= line('$')
        let child_indent = indent(lnum) / shiftwidth()
        if child_indent - curr_indent == 1
            call add(children, lnum)
        elseif child_indent - curr_indent < 1
            break
        endif
        let lnum += 1
    endwhile
    return children
endfunction

function! s:TodoFindKind(linenr)
    if <SID>TodoLineIsEmpty(a:linenr)
        return 'empty'
    elseif <SID>TodoLineIsOpen(a:linenr)
        return 'open'
    elseif <SID>TodoLineIsPartial(a:linenr)
        return 'partial'
    elseif <SID>TodoLineIsClosed(a:linenr)
        return 'closed'
    else
        return 'other'
    endif
endfunction

function! TodoFindOrphans()
    let orphans = []
    for lnum in range(1, line('$'))
        let parent = <SID>TodoFindParent(lnum)
        let self_is_orphan = <SID>TodoLineIsOrphan(lnum) && indent(lnum) != 0
        let parent_is_orphan = index(orphans, parent) >= 0

        if self_is_orphan || parent_is_orphan
            call add(orphans, lnum)
        endif
    endfor
    return orphans
endfunction

" }}}

" Line is {{{

function! s:TodoLineIsEmpty(linenr)
    return getline(a:linenr) =~# '^\s*$'
endfunction

function! s:TodoLineIsOpen(linenr)
    return match(getline(a:linenr), "\\V" . g:todo_completion_templates.open) != -1
endfunction

function! s:TodoLineIsPartial(linenr)
    if !g:todo_enable_partial_completion
        return 0
    endif
    return match(getline(a:linenr), "\\V" . g:todo_completion_templates.partial) != -1
endfunction

function! s:TodoLineIsClosed(linenr)
    return match(getline(a:linenr), "\\V" . g:todo_completion_templates.closed) != -1
endfunction

function! s:TodoLineIsTask(linenr)
    return <SID>TodoLineIsOpen(a:linenr)
        \ || <SID>TodoLineIsPartial(a:linenr)
        \ || <SID>TodoLineIsClosed(a:linenr)
endfunction

function! s:TodoLineIsParent(linenr)
    if a:linenr < 1 || a:linenr >= line('$')
        return v:false
    endif

    let curr_indent = indent(a:linenr) / shiftwidth()
    let child_indent = indent(a:linenr+1) / shiftwidth()

    return child_indent - curr_indent == 1
endfunction

function! s:TodoLineIsOrphan(lnum)
    return !(<SID>TodoLineIsEmpty(a:lnum) || <SID>TodoFindParent(a:lnum))
endfunction

function! s:TodoLineIsActive(linenr)
    if !g:todo_enable_active_status
        return 0
    endif
    return match(getline(a:linenr), "\\V" . g:todo_completion_templates.active . g:todo_completion_templates.open) != -1
        \ || (g:todo_enable_partial_completion && match(getline(a:linenr), "\\V" . g:todo_completion_templates.active . g:todo_completion_templates.partial) != -1)
        \ || match(getline(a:linenr), "\\V" . g:todo_completion_templates.active . g:todo_completion_templates.closed) != -1
endfunction

function! s:TodoLineIsTemplate(linenr)
    let kind = <SID>TodoFindKind(a:linenr)
    let pattern = "\\V"
    let pattern .= "\\^\\s\\*"
    let pattern .= g:todo_completion_templates[kind]
    let pattern .= "\\s\\*"
    let pattern .= "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.creation) . "\\)\\?"
    let pattern .= "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.update) . "\\)\\?"
    let pattern .= "\\$"
    return match(getline(a:linenr), pattern) != -1
endfunction

" }}}

" Date {{{

function! s:TodoLineAppendCreationDate(string)
    if g:todo_enable_creation_date
        return a:string . repeat(" ", shiftwidth()) . printf(g:todo_date_templates.creation, strftime(g:todo_date_format))
   else
       return a:string
   endif
endfunction

function! s:TodoLineAppendUpdateDate(string)
    if g:todo_enable_update_date
        return a:string . repeat(" ", shiftwidth()) . printf(g:todo_date_templates.update, strftime(g:todo_date_format))
   else
       return a:string
   endif
endfunction

function! s:TodoLineUpdateUpdateDate(string)
    let match = match(a:string, "\\V" . <SID>TodoEscapeDate(g:todo_date_templates.update))

    if match == -1
        return <SID>TodoLineAppendUpdateDate(a:string)
    else
        return <SID>TodoLineAppendUpdateDate(a:string[0:start])
    endif
endfunction

function! s:TodoEscapeDate(string)
    return substitute(a:string, '%s', '\\.\\{-\\}', '')
endfunction

function! s:TodoSetDateIndent()
    if !g:todo_enable_creation_date && !g:todo_enable_update_date
        return
    endif

    if g:todo_date_indent_header
        let headers = []
        " Iterate over all lines and find the headers
        for linenr in range(1, line('$'))
            if <SID>TodoLineIsTask(linenr) && indent(linenr) / shiftwidth() == 0
                call add(headers, linenr)
            endif
        endfor

        for header_index in range(len(headers))
            if header_index == len(headers)-1
                let last = line('$')
            else
                let last = headers[header_index+1]-1
            endif
            let first = headers[header_index]
            let [max_col, text_ends, start_cols] = <SID>TodoDateFindIndent(first, last)
            call <SID>TodoDateSetIndent(first, last, max_col, text_ends, start_cols)
        endfor
    else
        let [max_col, text_ends, start_cols] = <SID>TodoDateFindIndent(1, line('$'))
        call <SID>TodoDateSetIndent(1, line('$'), max_col, text_ends, start_cols)
    endif
endfunction

function! s:TodoDateFindIndent(first_lnum, last_lnum)
    let pattern_start = "\\V"
    let pattern = "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.creation) . "\\)\\?"
    let pattern .= "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.update) . "\\)\\?\\$"

    let text_ends = []
    let start_cols = []
    let max_col = 0
    for lnum in range(a:first_lnum, a:last_lnum)
        let line = getline(lnum)
        let start_col = match(line, pattern_start . pattern)
        let text_end = match(line, pattern_start . "\\s\\{-\\}" . pattern)
        if text_end > max_col
            let max_col = text_end
        endif
        call add(text_ends, text_end)
        call add(start_cols, start_col)
    endfor
    return [max_col, text_ends, start_cols]
endfunction

function! s:TodoDateSetIndent(first, last, max_col, text_ends, date_starts)
    for lnum in range(a:first, a:last)
        if <SID>TodoLineIsEmpty(lnum)
            continue
        endif
        let line = getline(lnum)
        let index = lnum - a:first

        let head = line[:a:text_ends[index]-1]
        let tail = line[a:date_starts[index]:]
        let space = repeat(" ", a:max_col - a:text_ends[index])

        if head !~? '^\s*$'
            call setline(lnum, head . space . tail)
        endif
    endfor
endfunction

" }}}

" Text objects {{{

function! s:TodoInnerTask() abort
    let lnum = line('.')
    if !<SID>TodoLineIsTask(lnum)
        return feedkeys("\<ESC>", 'n')
    endif

    normal! 0

    let kind = <SID>TodoFindKind(lnum)
    let line = getline(lnum)
    let start = matchend(line, "\\V" . g:todo_completion_templates[kind])
    let date_patterns  = "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.creation) . "\\)\\?"
    let date_patterns .= "\\(" . <SID>TodoEscapeDate(g:todo_date_templates.update) . "\\)\\?"
    let end = match(line, "\\V\\s\\{-\\}" . date_patterns . "\\$")

    call cursor(lnum, start+1)
    norm! v
    call cursor(lnum, end)
endfunction

function! s:TodoATask() abort
    let lnum = line('.')
    if !<SID>TodoLineIsTask(lnum)
        return feedkeys("\<ESC>", 'n')
    endif

    normal! 0
    
    let kind = <SID>TodoFindKind(lnum)
    let line = getline(lnum)
    let start = match(line, "\\V" . g:todo_completion_templates[kind])
    let end = col('$')-1

    call cursor(lnum, start+1)
    norm! v
    call cursor(lnum, end)
endfunction

function! s:TodoInnerParent() abort
    let lnum = line('.')
    if !<SID>TodoLineIsParent(lnum)
        return feedkeys("\<ESC>", 'n')
    endif

    norm! 0

    let start = lnum+1
    let end = lnum+1

    let children = <SID>TodoFindChildren(lnum)
    let has_children = !empty(children)

    while has_children
        let end = children[-1]
        let children = <SID>TodoFindChildren(children[-1])

        let has_children = !empty(children)
    endwhile

    exe start
    norm! V
    exe end
endfunction

function! s:TodoAParent() abort
    let lnum = line('.')
    if !<SID>TodoLineIsTask(lnum)
        return feedkeys("\<ESC>", 'n')
    endif

    norm! 0

    let start = lnum
    let end = lnum

    let children = <SID>TodoFindChildren(lnum)
    let has_children = !empty(children)

    while has_children
        let end = children[-1]
        let children = <SID>TodoFindChildren(children[-1])

        let has_children = !empty(children)
    endwhile

    if <SID>TodoLineIsEmpty(end+1)
        let end += 1
    endif

    exe start
    norm! V
    exe end
endfunction

" }}}

" Key mappings {{{

onoremap <buffer> <silent> iT :<C-U>call <SID>TodoInnerTask()<CR>
xnoremap <buffer> <silent> iT :<C-U>call <SID>TodoInnerTask()<CR>
onoremap <buffer> <silent> aT :<C-U>call <SID>TodoATask()<CR>
xnoremap <buffer> <silent> aT :<C-U>call <SID>TodoATask()<CR>
onoremap <buffer> <silent> iP :<C-U>call <SID>TodoInnerParent()<CR>
xnoremap <buffer> <silent> iP :<C-U>call <SID>TodoInnerParent()<CR>
onoremap <buffer> <silent> aP :<C-U>call <SID>TodoAParent()<CR>
xnoremap <buffer> <silent> aP :<C-U>call <SID>TodoAParent()<CR>

if g:todo_enable_active_status
    nnoremap <buffer> <silent> <Plug>(vim-todo-active) :<C-U>call <SID>TodoToggleActive()<CR>
endif

inoremap <buffer> <silent> <Plug>(vim-todo-new-inline) <CMD>call <SID>TodoNewTaskInline()<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-new)        <CMD>call <SID>TodoNewTask()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-o)          :<C-U>call <SID>TodoOpenTaskBelow()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-O)          :<C-U>call <SID>TodoOpenTaskAbove()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-I)          :<C-U>call <SID>TodoInsert()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-A)          :<C-U>call <SID>TodoAppend()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-complete)   :<C-U>call <SID>TodoToggleCompletion()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-indent-n)     :<C-U>call <SID>TodoIndent(mode(), v:false)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-indent-i)     <CMD>call <SID>TodoIndent(mode(), v:false)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-indent-g-n)   :<C-U>call <SID>TodoIndent(mode(), v:true)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-indent-g-i)   <CMD>call <SID>TodoIndent(mode(), v:true)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-deindent-n)   :<C-U>call <SID>TodoDeindent(mode(), v:false)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-deindent-i)   <CMD>call <SID>TodoDeindent(mode(), v:false)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-deindent-g-n) :<C-U>call <SID>TodoDeindent(mode(), v:true)<CR>
inoremap <buffer> <silent> <Plug>(vim-todo-deindent-g-i) <CMD>call <SID>TodoDeindent(mode(), v:true)<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-next-header) :<C-U>call <SID>TodoHeaderNext()<CR>
nnoremap <buffer> <silent> <Plug>(vim-todo-prev-header) :<C-U>call <SID>TodoHeaderPrev()<CR>

if g:todo_enable_default_bindings
    silent! nmap <buffer> <silent> o <Plug>(vim-todo-o)
    silent! nmap <buffer> <silent> O <Plug>(vim-todo-O)
    silent! nmap <buffer> <silent> I <Plug>(vim-todo-I)
    silent! nmap <buffer> <silent> A <Plug>(vim-todo-A)

    if g:todo_enable_active_status
        silent! nmap <buffer> <silent> <SPACE> <Plug>(vim-todo-active)
    endif

    execute("silent! imap <buffer> <silent> " . g:todo_inline_template[-1:-1] . " <Plug>(vim-todo-new-inline)")

    silent! imap <buffer> <silent> <CR> <Plug>(vim-todo-new)
    silent! imap <buffer> <silent> <C-q> <Plug>(vim-todo-new)

    silent! nmap <buffer> <silent> <CR> <Plug>(vim-todo-complete)
    silent! xmap <buffer> <silent> <CR> <Plug>(vim-todo-complete)

    silent! nmap <buffer> <silent> <TAB> <Plug>(vim-todo-indent-n)
    silent! imap <buffer> <silent> <TAB> <Plug>(vim-todo-indent-i)

    silent! nmap <buffer> <silent> g<TAB> <Plug>(vim-todo-indent-g-n)
    silent! imap <buffer> <silent> g<TAB> <Plug>(vim-todo-indent-g)

    silent! nmap <buffer> <silent> <S-TAB> <Plug>(vim-todo-deindent-n) 
    silent! imap <buffer> <silent> <S-TAB> <Plug>(vim-todo-deindent-i)

    silent! nmap <buffer> <silent> g<S-TAB> <Plug>(vim-todo-deindent-g-n)
    silent! imap <buffer> <silent> g<S-TAB> <Plug>(vim-todo-deindent-g-i)

    silent! nmap <buffer> <silent> <C-n> <Plug>(vim-todo-next-header)
    silent! nmap <buffer> <silent> <C-p> <Plug>(vim-todo-prev-header)
endif

" }}}

" Commands {{{

" Sort all tasks
command! -buffer TodoSort call <SID>TodoSort()

" Sort all tasks inside the block
command! -buffer TodoSortBlock call <SID>TodoSortBlock()

" Convert the lines in the given range into valid tasks
command! -buffer -nargs=? TodoConvert call <SID>TodoConvert(<q-args>)

" Hide virtual text
command! -buffer TodoHide call <SID>TodoHide()

" Show virtual text
command! -buffer TodoShow call <SID>TodoShow()

" }}}

" Autocommand {{{
augroup Todo
    autocmd!
    autocmd BufEnter * call <SID>TodoBufEnter()
    autocmd InsertLeave * call <SID>TodoInsertLeave()
augroup END

function! s:TodoBufEnter()
    if &filetype == 'todo'
        if g:todo_enable_orphan_highlight
            call <SID>TodoSetOrphanStatus()
        endif

        if g:todo_enable_virtual_text
            call <SID>TodoShow()
        endif

        if g:todo_enable_creation_date || g:todo_enable_update_date
            call <SID>TodoSetDateIndent()
        endif
    endif
endfunction

function! s:TodoInsertLeave()
    if &filetype == 'todo'
        call <SID>TodoSetDateIndent()
    endif
endfunction

" }}}
