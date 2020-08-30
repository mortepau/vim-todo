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

syntax match todoComment          '#.*'
syntax match todoHeader           '^\s*[^#[].*'       contains=todoComment
syntax match todoIncomplete       '^\s*\[ \] - .*$'   contains=todoComment
syntax match todoIncompleteActive '^\s*\[( )\] - .*$' contains=todoComment containedin=todoIncomplete
syntax match todoPartial          '^\s*\[/\] - .*$'   contains=todoComment
syntax match todoPartialActive    '^\s*\[(/)\] - .*$' contains=todoComment containedin=todoPartial
syntax match todoComplete         '^\s*\[x\] - .*$'   contains=todoComment
syntax match todoCompleteActive   '^\s*\[(x)\] - .*$' contains=todoComment containedin=todoComplete
" syntax match todoActive '^\s*\[(\(x\|/\| \))\] - .*$' contains=todoComment containedin=todoIncomplete,todoComplete,todoPartial

hi def link todoHeader           Statement
hi def link todoComment          Comment
hi def link todoComplete         Comment
hi def link todoCompleteActive   Comment
hi def link todoIncomplete       Normal
hi def link todoIncompleteActive String
hi def link todoPartial          Special
hi def link todoPartialActive    Constant

let b:current_syntax = "todo"

if main_syntax == "todo"
    unlet main_syntax
endif

let &cpo = s:cpo_save
unlet s:cpo_save
