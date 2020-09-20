" Todo syntax file
" Language:   todo
" Maintainer: Morten Paulsen <morten.p96@gmail.com>
" Last Change: 2020 Aug 26

if !exists("main_syntax")
    if exists("b:current_syntax")
        finish
    endif
    let main_syntax = "todo"
endif

let s:cpo_save = &cpo
set cpo&vim

if g:todo_enable_virtual_text
    execute("highlight todoRed guifg=" . g:todo_virtual_text_colors.red . " ctermfg=" . g:todo_virtual_text_colors.red)
    execute("highlight todoYellow guifg=" . g:todo_virtual_text_colors.yellow . " ctermfg=" . g:todo_virtual_text_colors.yellow)
    execute("highlight todoGreen guifg=" . g:todo_virtual_text_colors.green . " ctermfg=" . g:todo_virtual_text_colors.green)
endif

execute("syntax match todoTickOpen '^\\s*\\zs\\V" . g:todo_completion_templates.open . "\\ze' conceal")
if g:todo_enable_active_status
    execute("syntax region todoTaskOpen matchgroup=todoTickOpen start='\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates.open . "' end='$' concealends")
else
    execute("syntax region todoTaskOpen matchgroup=todoTickOpen start='\\V" . g:todo_completion_templates.open . "' end='$' concealends")
endif

execute("syntax match todoTickClosed '^\\s*\\zs\\V" . g:todo_completion_templates.closed . "\\ze' conceal")
if g:todo_enable_active_status
    execute("syntax region todoTaskClosed matchgroup=todoTickClosed start='\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates.closed . "' end='$' concealends")
else
    execute("syntax region todoTaskClosed matchgroup=todoTickClosed start='\\V" . g:todo_completion_templates.closed . "' end='$' concealends")
endif

if g:todo_enable_partial_completion
    execute("syntax match todoTickPartial '^\\s*\\zs\\V" . g:todo_completion_templates.partial . "\\ze' conceal")
    if g:todo_enable_active_status
        execute("syntax region todoTaskPartial matchgroup=todoTickPartial start='\\V" . g:todo_completion_templates.active . "\\?" . g:todo_completion_templates.partial . "' end='$' concealends")
    else
        execute("syntax region todoTaskPartial matchgroup=todoTickPartial start='\\V" . g:todo_completion_templates.partial . "' end='$' concealends")
    endif
endif

if g:todo_enable_active_status
    execute("syntax match todoTickActive '^\\s*\\zs\\V" . g:todo_completion_templates.active . g:todo_completion_templates.open . "\\ze' conceal")
    execute("syntax match todoTickActive '^\\s*\\zs\\V" . g:todo_completion_templates.active . g:todo_completion_templates.closed . "\\ze' conceal")
    if g:todo_enable_partial_completion
        execute("syntax match todoTickActive '^\\s*\\zs\\V" . g:todo_completion_templates.active . g:todo_completion_templates.partial . "\\ze' conceal")
    endif
endif

if g:todo_enable_partial_completion
    let s:header = "\\(" . g:todo_completion_templates.open . "\\|" . g:todo_completion_templates.partial . "\\)"
    if g:todo_enable_active_status
        let s:active = g:todo_completion_templates.active . s:header
        let s:header = g:todo_completion_templates.active . "\\?" . s:header
    endif
else
    let s:header = g:todo_completion_templates.open
    if g:todo_enable_active_status
        let s:active = g:todo_completion_templates.active . s:header
        let s:header = g:todo_completion_templates.active . "\\?" . s:header
    endif
endif

execute("syntax match todoTickHeader '^\\zs\\V" . s:header . "\\ze' conceal")
execute("syntax region todoTaskHeader matchgroup=todoTickHeader start='^\\V" . s:header . "' end='$' concealends")

if g:todo_enable_active_status
    execute("syntax region todoTaskActive matchgroup=todoTickActive start='\\V" . s:active . "' end='$' concealends")
endif

execute("highlight def link todoTaskHeader " . g:todo_task_colors.header)
execute("highlight def link todoTickHeader " . g:todo_task_colors.header)

execute("highlight def link todoTaskOpen " . g:todo_task_colors.open)
execute("highlight def link todoTickOpen " . g:todo_task_colors.open)

if g:todo_enable_partial_completion
    execute("highlight def link todoTaskPartial " . g:todo_task_colors.partial)
    execute("highlight def link todoTickPartial " . g:todo_task_colors.partial)
endif

execute("highlight def link todoTaskClosed " . g:todo_task_colors.closed)
execute("highlight def link todoTickClosed " . g:todo_task_colors.closed)

if g:todo_enable_active_status
    execute("highlight def link todoTaskActive " . g:todo_task_colors.active)
    execute("highlight def link todoTickActive " . g:todo_task_colors.active)
endif

let b:current_syntax = "todo"

if main_syntax == "todo"
    unlet main_syntax
endif

let &cpo = s:cpo_save
unlet s:cpo_save
