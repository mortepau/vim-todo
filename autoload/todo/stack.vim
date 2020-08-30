function! todo#stack#new()
    let stack = {
        \ '__struct__': 'stack',
        \ 'values': []
        \ }
    return stack
endfunction

function! todo#stack#push(...)
    if a:0 == 0
        return
    endif
        if todo#stack#valid(a:1)
            for arg in a:000[1:]
                echo "Pushing " . arg . " onto a:1"
                call add(a:1.values, arg)
            endfor
        else
            if !exists('b:stack')
                echo "Creating b:stack"
                let b:stack = todo#stack#new()
            endif
            for arg in a:000
                echo "Pushing " . arg . " onto b:stack.values"
                call add(b:stack.values, arg)
            endfor
        endif
endfunction

function! todo#stack#pop(...)
    if a:0 == 0
        let val = remove(b:stack.values, -1)
    elseif a:0 == 1 && todo#stack#valid(a:1)
        let val = remove(a:1.values, -1)
    else
        let val = v:null
    endif
    return val
endfunction

function! todo#stack#valid(stack)
    if type(a:stack) != v:t_dict
        return v:false
    endif
    return has_key(a:stack, '__struct__') && a:stack.__struct__ ==? 'stack'
endfunction

function! todo#stack#popp(...)
    if a:0 > 0
        if !todo#stack#valid(a:1)
            echo a:1
            return v:null
        endif
        let val = remove(a:1.values, -1)
        return val
    else
        let val = remove(b:stack.values, -1)
        return val
    endif
endfunction
