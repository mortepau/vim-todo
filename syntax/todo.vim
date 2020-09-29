" Todo syntax file
" Language:   todo
" Maintainer: Morten Paulsen <morten.p96@gmail.com>
" Last Change: 2020 Sept 20

if !exists("main_syntax")
    if exists("b:current_syntax")
        finish
    endif
    let main_syntax = "todo"
endif

let s:cpo_save = &cpo
set cpo&vim

" Virtual text highlight colors
execute("highlight todoRed guifg=" . g:todo_virtual_text_colors.red . " ctermfg=" . g:todo_virtual_text_colors.red)
execute("highlight todoYellow guifg=" . g:todo_virtual_text_colors.yellow . " ctermfg=" . g:todo_virtual_text_colors.yellow)
execute("highlight todoGreen guifg=" . g:todo_virtual_text_colors.green . " ctermfg=" . g:todo_virtual_text_colors.green)

" Dates
execute("syntax match todoDateCreation '\\V (Created: \\.\\{-\\})'")
execute("syntax match todoDateUpdated '\\V (Updated: \\.\\{-\\})'")

" Open task tick and task text
execute("syntax match todoTickOpen '^\\s*\\zs\\V" . g:todo_completion_templates.open . "\\ze' conceal")
execute("syntax region todoTaskOpen matchgroup=todoTickOpen start='\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates.open . "' end='$' concealends contains=todoDateCreation,todoDateUpdated")

" Closed task tick and task text
execute("syntax match todoTickClosed '^\\s*\\zs\\V" . g:todo_completion_templates.closed . "\\ze' conceal")
execute("syntax region todoTaskClosed matchgroup=todoTickClosed start='\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates.closed . "' end='$' concealends contains=todoDateCreation,todoDateUpdated")

" Partial task tick and task text
execute("syntax match todoTickPartial '^\\s*\\zs\\V" . g:todo_completion_templates.partial . "\\ze' conceal")
execute("syntax region todoTaskPartial matchgroup=todoTickPartial start='\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates.partial . "' end='$' concealends contains=todoDateCreation,todoDateUpdated")

" Active task tick
execute("syntax match todoTickActive '^\\s*\\zs\\V" . g:todo_completion_templates.active . g:todo_completion_templates.open . "\\ze' conceal")
execute("syntax match todoTickActive '^\\s*\\zs\\V" . g:todo_completion_templates.active . g:todo_completion_templates.closed . "\\ze' conceal")
execute("syntax match todoTickActive '^\\s*\\zs\\V" . g:todo_completion_templates.active . g:todo_completion_templates.partial . "\\ze' conceal")

" Header task tick
let s:header = "\\(" . g:todo_completion_templates.open . "\\|" . g:todo_completion_templates.partial . "\\)"
let s:active = g:todo_completion_templates.active . s:header
let s:header = g:todo_completion_templates.active . "\\?" . s:header

execute("syntax match todoTickHeader '^\\zs\\V" . s:header . "\\ze' conceal")
execute("syntax region todoTaskHeader matchgroup=todoTickHeader start='^\\V" . s:header . "' end='$' concealends contains=todoDateCreation,todoDateUpdated")

execute("syntax region todoTaskActive matchgroup=todoTickActive start='\\V" . s:active . "' end='$' concealends contains=todoDateCreation,todoDateUpdated")

execute("highlight def link todoTaskHeader " . g:todo_task_colors.header)
execute("highlight def link todoTickHeader " . g:todo_task_colors.header)

execute("highlight def link todoTaskOpen " . g:todo_task_colors.open)
execute("highlight def link todoTickOpen " . g:todo_task_colors.open)

execute("highlight def link todoTaskPartial " . g:todo_task_colors.partial)
execute("highlight def link todoTickPartial " . g:todo_task_colors.partial)

execute("highlight def link todoTaskClosed " . g:todo_task_colors.closed)
execute("highlight def link todoTickClosed " . g:todo_task_colors.closed)

execute("highlight def link todoTaskActive " . g:todo_task_colors.active)
execute("highlight def link todoTickActive " . g:todo_task_colors.active)

execute("highlight def link todoDateCreation " . g:todo_date_colors.creation)
execute("highlight def link todoDateUpdated " . g:todo_date_colors.update)

let b:current_syntax = "todo"

if main_syntax == "todo"
    unlet main_syntax
endif

let &cpo = s:cpo_save
unlet s:cpo_save
