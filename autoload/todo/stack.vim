function! todo#stack#new()
    let stack = {
        \ '__struct__': 'stack',
        \ 'values': []
        \ }
    return stack
endfunction

function! todo#stack#push(...)
    if a:0 == 0
        " No input
        return
    endif
    if todo#stack#valid(a:1)
        let stack = a:1
        let args = a:000[1:]
    else
        " Create b:stack if it doesn't exist
        if !exists('b:stack')
            let b:stack = todo#stack#new()
        endif
        let stack = b:stack
        let args = a:000
    endif
    for arg in args
        call add(stack.values, arg)
    endfor
endfunction

function! todo#stack#pop(...)
    if a:0 == 0 && exists('b:stack')
        let stack = b:stack
    elseif a:0 == 1 && todo#stack#valid(a:1)
        let stack = a:1
    else
        " Wrong number of arguments or invalid stack
        return v:null
    endif
    if !todo#stack#empty(stack)
        let val = remove(stack.values, -1)
        return val
    else
        " Stack is empty
        return v:null
    endif
endfunction

function! todo#stack#valid(stack)
    if type(a:stack) != v:t_dict
        return v:false
    endif
    return has_key(a:stack, '__struct__') && a:stack.__struct__ ==? 'stack'
endfunction

function! todo#stack#empty(stack)
    return len(stack.values) == 0
endfunction
