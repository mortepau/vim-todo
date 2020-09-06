if exists("g:loaded_todo")
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:todo_default_keymap = {
    \ 'indent': "\<TAB>",
    \ 'outdent': "\<S-TAB>",
    \ 'open_below': "o",
    \ 'open_above': "O",
    \ 'complete': "\<CR>",
    \ 'new_line': "\<CR>",
    \ 'sort': "R",
    \ }
let s:todo_default_next_state = {
    \ "completion": {
        \ " ": "/",
        \ "/": "x",
        \ "x": " ",
        \ "( )": "(/)",
        \ "(/)": "x",
        \ "(x)": "( )",
        \ },
    \ "status": {
        \ " ": "( )",
        \ "/": "(/)",
        \ "x": "x",
        \ "( )": " ",
        \ "(/)": "/",
        \ "(x)": "x",
        \ },
    \ }
let s:todo_default_conversion = {
    \ 'integer': {
        \ 4: 'closed',
        \ 3: 'partial',
        \ 2: 'open',
        \ 1: 'comment',
        \ 0: 'header',
        \ -1: 'default',
        \ },
    \ 'completion': {
        \ 'closed': 4,
        \ 'partial': 3,
        \ 'open': 2,
        \ 'comment': 1,
        \ 'header': 0,
        \ 'default': -1,
        \ },
    \ 'marker': {
            \ 'closed': 'x',
            \ 'partial': '/',
            \ 'open': ' ',
            \ 'comment': '',
            \ 'header': '',
            \ 'default': '',
        \ }
    \ }

if !has_key(g:, 'todo_keymap')
    let g:todo_keymap = s:todo_default_keymap
else
    call extend(g:todo_keymap, s:todo_default_keymap, "keep")
endif

if !has_key(g:, 'todo_next_state')
    let g:todo_next_state = {}
endif

if has_key(g:todo_next_state, 'completion')
    call extend(g:todo_next_state.completion, s:todo_default_next_state.completion, "keep")
else 
    let g:todo_next_state.completion = s:todo_default_next_state.completion
endif

if has_key(g:todo_next_state, 'status')
    call extend(g:todo_next_state.status, s:todo_default_next_state.status, "keep")
else
    let g:todo_next_state.status = s:todo_default_next_state.status
endif

if !has_key(g:, 'todo_conversion_table')
    let g:todo_conversion_table = {}
endif

if has_key(g:todo_conversion_table, 'completion')
    call extend(g:todo_conversion_table.completion, s:todo_default_conversion.completion, "keep")
else
    let g:todo_conversion_table.completion = s:todo_default_conversion.completion
endif

if has_key(g:todo_conversion_table, 'integer')
    call extend(g:todo_conversion_table.integer, s:todo_default_conversion.integer, "keep")
else
    let g:todo_conversion_table.integer = s:todo_default_conversion.integer
endif

if has_key(g:todo_conversion_table, 'marker')
    call extend(g:todo_conversion_table.marker, s:todo_default_conversion.marker, "keep")
else
    let g:todo_conversion_table.marker = s:todo_default_conversion.marker
endif

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_todo = 1
