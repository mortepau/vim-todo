function! todo#block#new(...)
    let values = []
    if len(a:000) > 0
        for v in a:000
            let values += [v]
        endfor
    endif
    let block = {'values': values, '__struct__': 'block'}
    return block
endfunction

function! todo#block#append(block, value)
    if !has_key(block, '__struct__') || dict.key !=? 'block'
        return v:nil
    endif

    let block = a:block
    let block.values += [a:value]
    return block
endfunction

function! todo#block#is_block(block)
    if type(block) != v:t_dict
        return v:false
    endif
    return !has_key(block, '__struct__') || block.__struct__ !=? 'block'
endfunction

function! todo#block#get_head(block)
    if !todo#block#is_block(block)
        return v:nil
    endif
    if !has_key(block, '__struct__')
        return v:nil
    endif
    let block = a:block
    if len(block.values) > 0
        let values = block.values
        while type(values) == v:t_list
            let values = values[0]
        endwhile
        return values
    else
        return block
    endif
        
    if len()
    if len(a:list) == 0
        return a:list
    endif
    let l = a:list
    while type(l) == v:t_list
        let l = l[0]
    endwhile
    return l
endfunction

function! todo#block#remove_tail(block)
    let block = a:block
    let block.values = block.values[:-2]
    return block
endfunction
