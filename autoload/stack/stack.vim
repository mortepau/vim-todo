function! todo#stack#push(...)
    if len(a:000) > 0
        if !todo#stack#valid(a:0)
            let stack = s:stack
            let stack += [a:0]
        else
            let stack = a:0
            let stack += [a:1]
        endif
        return stack
    endif
    return v:nil
endfunction

function! todo#stack#pop(...)
    if len(a:000) > 0
        if !todo#stack#valid(a:0)
            return a:000
        else
            let stack = a:0
        endif
    else
        let s:stack = s:stack
    endif
endfunction

function! todo#stack#valid(stack)
    if type(a:stack) != v:t_dict
        return v:false
    endif
    return !has_key(a:stack, '__struct__') || a:stack.__struct__ !=? 'stack'
endfunction
