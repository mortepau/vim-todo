if exists("g:loaded_todo")
    finish
endif

let g:todo_indent = get(g:, 'todo_indent', '\<TAB>')
let g:todo_outdent = get(g:, 'todo_outdent', '\<S-TAB>')
let g:todo_open_below = get(g:, 'todo_open_below', 'o')
let g:todo_open_above = get(g:, 'todo_open_above', 'O')
let g:todo_toggle_completion = get(g:, 'todo_toggle_completion', '\<CR>')
let g:stack = todo#stack#new()

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_todo = 1
