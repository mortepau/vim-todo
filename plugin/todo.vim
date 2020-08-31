if exists("g:loaded_todo")
    finish
endif

let g:todo_indent = get(g:, 'todo_indent', '\<TAB>')
let g:todo_outdent = get(g:, 'todo_outdent', '\<S-TAB>')
let g:todo_open_below = get(g:, 'todo_open_below', 'o')
let g:todo_open_above = get(g:, 'todo_open_above', 'O')
let g:todo_toggle_completion = get(g:, 'todo_toggle_completion', '\<CR>')

let g:todo_completion_next_state = {
    \ 'x'   : ' ',
    \ '/'   : 'x',
    \ ' '   : '/',
    \ '(x)' : '( )',
    \ '(/)' : 'x',
    \ '( )' : '(/)',
    \ }
let g:todo_active_next_state = {
    \ 'x'   : 'x',
    \ '/'   : '(/)',
    \ ' '   : '( )',
    \ '(x)' : 'x',
    \ '(/)' : '/',
    \ '( )' : ' ',
    \ }
let g:todo_completion_to_integer = {
    \ 'complete': 2,
    \ 'partial': 1,
    \ 'incomplete': 0,
    \ 'header': -1,
    \ 'comment': -2,
    \ 'default': -3,
    \ }
let g:todo_integer_to_completion = {
    \ 2: 'complete',
    \ 1: 'partial',
    \ 0: 'incomplete',
    \ -1: 'header',
    \ -2: 'comment',
    \ -3: 'default',
    \ }
let g:todo_completion_to_marker = {
    \ 2: 'x',
    \ 1: '/',
    \ 0: ' ',
    \ -1: '',
    \ -2: '',
    \ -3: '',
    \ }

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_todo = 1
