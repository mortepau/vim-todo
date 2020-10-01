if exists("g:loaded_todo")
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add partial to the allowed completion states
let g:todo_enable_partial_completion = get(g:, 'todo_enable_partial_completion', v:true)

" Add active as a possible co-status, i.e. a task can be open and active at the same time
let g:todo_enable_active_status = get(g:, 'todo_enable_active_status', v:true)

" Auto-sort tasks on change
let g:todo_enable_auto_sort = get(g:, 'todo_enable_auto_sort', v:true)

" Enable conceal feature
let g:todo_enable_conceal = get(g:, 'todo_enable_conceal', v:true)

" Enable virtual text showing percentage completion ++
let g:todo_enable_virtual_text = get(g:, 'todo_enable_virtual_text', v:true)

" Enable highlighting of orphans
let g:todo_enable_orphan_highlight = get(g:, 'todo_enable_orphan_highlight', v:true)

" Add percentage completion to all entries
let g:todo_enable_percentage_completion = get(g:, 'todo_enable_percentage_completion', v:true)

" Add creation date to all entries
let g:todo_enable_creation_date = get(g:, 'todo_enable_creation_date', v:true)

" Add last updated date to all entries
let g:todo_enable_update_date = get(g:, 'todo_enable_update_date', v:true)

" Date format to use
let g:todo_date_format = get(g:, 'todo_date_format', "%d %h. %Y %H:%M")

" Indent date based on max width among header children
let g:todo_date_indent_header = get(g:, 'todo_date_indent_header', v:true)

" Update task completion automatically based on parent and/or children
let g:todo_auto_update_tasks = get(g:, 'todo_auto_update_tasks', v:true)

" Update virtual text automatically on changes
let g:todo_auto_update_virtual_text = get(g:, 'todo_auto_update_virtual_text', v:true)

" Create mappings
let g:todo_enable_default_bindings = get(g:, 'todo_enable_default_bindings', v:true)

" Word to write to create a new task inline
let g:todo_inline_template = get(g:, 'todo_inline_template', 'new')

" In which order to sort keys
let s:default_values = ['active', 'open', 'partial', 'closed']
if exists('g:todo_sorting_priority')
    let s:valid_keys = ['open', 'closed', 'partial', 'active']
    if type(g:todo_sorting_priority) == v:t_list
        for key in g:todo_sorting_priority
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_sorting_priority: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_sorting_priority, 'v:val != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_sorting_priority must be a List."
    endif
    call extend(g:todo_sorting_priority, s:default_values, 'keep')
else
    let g:todo_sorting_priority = s:default_values
endif

" How the different task templates look
let s:default_values = {
    \ 'open': '[ ] - ',
    \ 'closed': '[X] - ',
    \ 'partial': '[/] - ',
    \ 'active': '!',
\ }
if exists('g:todo_completion_templates')
    let s:valid_keys = ['open', 'closed', 'partial', 'active']
    if type(g:todo_completion_templates) == v:t_dict
        for key in keys(g:todo_completion_templates)
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_completion_templates: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_completion_templates, 'v:key != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_completion_templates must be a Dict."
    endif
    call extend(g:todo_completion_templates, s:default_values, 'keep')
else
    let g:todo_completion_templates = s:default_values
endif

let s:default_values = {
    \ 'open': 'o',
    \ 'closed': 'c',
    \ 'partial': 'p',
    \ 'active': 'a',
\ }
if exists('g:todo_task_cchar')
    let s:valid_keys = ['open', 'closed', 'partial', 'active']
    if type(g:todo_task_cchar) == v:t_dict
        for key in keys(g:todo_task_cchar)
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_task_cchar: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_task_cchar, 'v:key != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_task_cchar must be a Dict."
    endif
    call extend(g:todo_task_cchar, s:default_values, 'keep')
else
    let g:todo_task_cchar = s:default_values
endif

let s:default_values = {
    \ 'open': 'Ignore',
    \ 'closed': 'Comment',
    \ 'header': 'Statement',
    \ 'partial': 'Type',
    \ 'active': 'Identifier',
\ }
if exists('g:todo_task_colors')
    let s:valid_keys = ['open', 'closed', 'header', 'partial', 'active']
    if type(g:todo_task_colors) == v:t_dict
        for key in keys(g:todo_task_colors)
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_task_colors: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_task_colors, 'v:key != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_task_colors must be a Dict."
    endif
    call extend(g:todo_task_colors, s:default_values, 'keep')
else
    let g:todo_task_colors = s:default_values
endif

let s:default_values = {
    \ 'creation': 'Define',
    \ 'update': 'Keyword',
\ }
if exists('g:todo_date_colors')
    let s:valid_keys = ['creation', 'update']
    if type(g:todo_date_colors) == v:t_dict
        for key in keys(g:todo_date_colors)
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_date_colors: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_date_colors, 'v:key != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_date_colors must be a Dict."
    endif
    call extend(g:todo_date_colors, s:default_values, 'keep')
else
    let g:todo_date_colors = s:default_values
endif

let s:default_values = {
    \ 'creation': '  (Created: %s)',
    \ 'update': '  (Updated: %s)',
\ }
if exists('g:todo_date_templates')
    let s:valid_keys = ['creation', 'update']
    if type(g:todo_date_templates) == v:t_dict
        for key in keys(g:todo_date_templates)
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_date_templates: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_date_templates, 'v:key != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_date_templates must be a Dict."
    endif
    call extend(g:todo_date_templates, s:default_values, 'keep')
else
    let g:todo_date_templates = s:default_values
endif

let s:default_values = {
    \ 'red': 'DarkRed',
    \ 'yellow': 'DarkYellow',
    \ 'green': 'DarkGreen',
\ }
if exists('g:todo_virtual_text_colors')
    let s:valid_keys = ['red', 'yellow', 'green']
    if type(g:todo_virtual_text_colors) == v:t_dict
        for key in keys(g:todo_virtual_text_colors)
            if index(s:valid_keys, key) == -1
                echoerr "vim-todo: Invalid key in g:todo_virtual_text_colors: " . key . ". Valid keys are: " . string(s:valid_keys) . "."
                call filter(g:todo_virtual_text_colors, 'v:key != ' . key)
            endif
        endfor
    else
        echoerr "vim-todo: Invalid type, g:todo_virtual_text_colors must be a Dict."
    endif
    call extend(g:todo_virtual_text_colors, s:default_values, 'keep')
else
    let g:todo_virtual_text_colors = s:default_values
endif

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_todo = 1
