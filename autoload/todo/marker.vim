function! todo#marker#new()
    let marker = {
        \ '__struct__': 'marker',
        \ 'start': -1,
        \ 'end': -1,
        \ 'value': '',
        \ 'size': 0,
        \ }
    return marker
endfunction

function! todo#marker#set_value(marker, value)
    if todo#marker#valid(a:marker)
        let a:marker.value = a:value
        let a:marker.size = len(a:value)
        call todo#marker#set_start(a:marker, a:marker.start)
    endif
endfunction

function! todo#marker#set_start(marker, value)
    if todo#marker#valid(a:marker)
        let a:marker.start = a:value
        if a:marker.size == 0
            let a:marker.end = a:value + a:marker.size
        else
            let a:marker.end = a:value + a:marker.size - 1
        endif
    endif
endfunction

function! todo#marker#valid(marker)
    if type(a:marker) != v:t_dict
        return v:false
    endif
    return has_key(a:marker, '__struct__') && a:marker.__struct__ ==? 'marker'
endfunction
