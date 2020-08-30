if exists("g:loaded_todo")
    finish
endif

if !exists('g:todo_indent')
    let g:todo_indent = '\<TAB>'
endif

if !exists('g:todo_outdent')
    let g:todo_outdent = '\<S-TAB>'
endif

if !exists('g:todo_open_below')
    let g:todo_indent = 'o'
endif

if !exists('g:todo_open_above')
    let g:todo_indent = 'O'
endif

if !exists('g:todo_toggle_completion')
    let g:todo_toggle_completion = '\<CR>'
endif

let s:save_cpo = &cpo
set cpo&vim

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_todo = 1
