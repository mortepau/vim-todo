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

syntax match todoHeader '^[\(x\|/\| \|(x)\|(/)\|( )\)] -\s\+'

syntax match todoTickOpen    '^\s*\zs\[ \] -\ze'   conceal
syntax match todoTickPartial '^\s*\zs\[/\] -\ze'   conceal
syntax match todoTickClosed  '^\s*\zs\[x\] -\ze'   conceal
syntax match todoTickActive  '^\s*\zs\[( )\] -\ze' conceal
syntax match todoTickActive  '^\s*\zs\[(/)\] -\ze' conceal
syntax match todoTickActive  '^\s*\zs\[(x)\] -\ze' conceal
syntax match todoTickHeader  '^\zs\[\(( )\|(/)\| \|/\)\] -\ze' conceal

syntax region todoTaskOpen    matchgroup=todoTickOpen    start='\[\( \|( )\)\] -\s\+'    end='$' concealends
syntax region todoTaskPartial matchgroup=todoTickPartial start='\[\(/\|(/)\)\] -\s\+'    end='$' concealends
syntax region todoTaskClosed  matchgroup=todoTickClosed  start='\[\(x\|(x)\)\] -\s\+'    end='$' concealends
syntax region todoTaskActive  matchgroup=todoTickActive  start='\[(\(x\|/\| \))\] -\s\+' end='$' concealends
syntax region todoTaskHeader  matchgroup=todoTickHeader  start='^\[\(\(/\| \)\|\(( )\|(/)\)\)\] -\s\+'    end='$' concealends

highlight def link todoTaskHeader Statement
highlight def link todoTickHeader Statement

highlight def link todoTaskOpen Ignore
highlight def link todoTickOpen Ignore
highlight def link todoTaskPartial Type
highlight def link todoTickPartial Type
highlight def link todoTaskClosed Comment
highlight def link todoTickClosed Comment
highlight def link todoTaskActive Identifier
highlight def link todoTickActive Identifier


let b:current_syntax = "todo"

if main_syntax == "todo"
    unlet main_syntax
endif

let &cpo = s:cpo_save
unlet s:cpo_save
