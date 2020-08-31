function! todo#block#new()
    let block = {
        \ '__struct__': 'block',
        \ 'values': []
        \ }
    return block
endfunction

function! todo#block#insert(block, value, ...)
    " Check if block is valid
    if !todo#block#valid(a:block)
        echo "Invalid block"
        return
    endif

    " Check if index is given as parameter
    if a:0 == 1
        echo "Valid index"
        let index = todo#block#clamp(a:block, a:1)
    else
        " Insert at tail
        echo "Insert at tail"
        let index = len(a:block.values)
    endif

    call insert(a:block.values, a:value, index)
endfunction

function! todo#block#remove(block, ...)
    " Check if block is valid
    if !todo#block#valid(a:block)
        echo "Invalid block"
        return v:null
    endif

    " Check if index is given as parameter
    if a:0 == 1
        echo "Valid index"
        let index = todo#block#clamp(a:block, a:1)
    else
        " Remove tail
        echo "Removing tail"
        let index = len(a:block.values) - 1
    endif

    " Check if the block isn't empty
    if !todo#block#empty(a:block)
        echo "Removing entry from block"
        return remove(a:block.values, index)
    else
        echo "Invalid size on block"
        return v:null
    endif
endfunction

function! todo#block#head(block)
    return a:block.values[0]
endfunction

function! todo#block#tail(block)
    return a:block.values[-1]
endfunction

function! todo#block#valid(block)
    if type(a:block) != v:t_dict
        return v:false
    endif
    return has_key(a:block, '__struct__') && a:block.__struct__ ==? 'block'
endfunction

function! todo#block#empty(block)
    return len(a:block.values) == 0
endfunction

function! todo#block#clamp(block, index)
    return max([0, min([a:index, len(a:block.values) - 1])])
endfunction
