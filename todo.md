# vim-todo

A simple plugin providing the necessary configurations to keep track of your tasks.

## Keybindings

`o` - Create a new task below the current one, keep indentation based on the level of the current line

`O` - Create a new task above the current one, keep indentation based on the level of the current line

`<CR>` - Toggle the completion of the current task, Set possible levels(?) [ "x", "/", " " ] <=> [ complete, partial, incomplete ]

`<TAB>` - Increase indentation of current task

`<S-TAB>` - Decrease indentation of current task

## Detection

Detects all files following either of these nameschemes:
- "*.todo$"
- "^\\<todo\\>$"

## Commands

`sort` - Sort lines based on completion rate, order can be specified by `g:vim_todo_ordering`. Can either take a range or sort all lines

## Variables

`g:vim_todo_use_partial` - if true use partial completion when toggling, otherwise don't. (Default: v:true)

`g:vim_todo_ordering` - set ordering of sorting, can be one of ("normal", "reverse" or "partialfirst"). (Default: "normal")

## Information

A task is considered partially complete when all of its subtasks are 50% complete or more, but less than 100% complete

Why use HEADERS? - Because it should fold based on header and doesn't fold on comments

Bot headers and comments are tied to the first task below their current line, or in the case for comments


Example of file
```
A HEADER
# A comment
[/] - Incomplete task 1
    A SUB-HEADER
    [ ] - Incomplete task 2, subtask of 1
    [x] - Complete task 3, subtask of 1
        [x] - Complete task 4, subtask of 3

ANOTHER HEADER
[x] - Complete task 1
    [x] - Complete task 2
    [x] - Complete task 3
        [x] - Complete task 4
```


Sorting
```
HEADER block [62] blocks []
#comment block [62, 63] blocks []
[x] - 1 block [62, 63, 64] blocks []
    [x] - 2 block [65] blocks [[62,63,64]]
    [x] - 3 block [65, 66] blocks [[62, 63, 64]]
    [x] - 4 block [65, 66, 67] blocks [[62, 63, 64]]
        [x] - 5 block [68] blocks [[62, 63, 64], [65,66, 67]]
        [x] - 6 block [68, 69] blocks [[62, 63, 64], [65,66, 67]] 
        pre: block [68, 69], stack [[62, 63, 64], [65, 66, 67]]
        1: block [68, 69] prevblock [65, 66, 67], stack [[62, 63, 64]]
        2: block [65, 66, 67, [68, 69]], stack [[62, 63, 64]]
        3: block [65, 66, 67, [68, 69]], prevblock [62,63,64], stack []
        4: block [62,63,64, [65, 66, 67, [68, 69]]], stack []
        post: block [62,63,64, [65, 66, 67, [68, 69]]], stack []
    [x] - 7 block [70] blocks [[62, 63, 64 [65, 66, 67 [68, 69]]]]
        [x] - 8 block [71] blocks [[62, 63, 64 [65, 66, 67 [68, 69]]], [70]]
    [x] - 9 block [72] blocks [62, 63, 64 [65, 66, 67 [68, 69]] [70 [71]]]
ANOTHER HEADER block [73] blocks [62, 63, 64 [65, 66, 67 [68, 69]] [70 [71]] [72]]
# comment
[/] - 10
    [ ] - 11
        [ ] - 12
        [ ] - 13
        [/] - 14
        [ ] - 15
    [x] - 16
        [x] - 17
        [x] - 18
[ ] - 19
    [x] - 20
        [x] - 21
    [/] - 22
        [x] - 23
        [ ] - 24
    [ ] - 25
        [ ] - 26
        [ ] - 27
    [ ] - 28
        [ ] - 29

----------------------

[ ] - 19
    [ ] - 25
        [ ] - 26
        [ ] - 27
    [ ] - 28
        [ ] - 29
    [/] - 22
        [x] - 23
        [ ] - 24
    [x] - 20
        [x] - 21
ANOTHER HEADER
#comment
[/] - 10
    [ ] - 11
        [ ] - 12
        [ ] - 13
        [ ] - 15
        [/] - 14
    [x] - 16
        [x] - 17
        [x] - 18
HEADER
#comment
[x] - 1
    [x] - 2
    [x] - 3
    [x] - 4
        [x] - 5
        [x] - 6
    [x] - 7
        [x] - 8
    [x] - 9
```

### Pseudo code
```vim
function! Sort(start, end)
    let lines = getlines(start, end)
    let cindent = 0
    let stack = []
    let block = []
    for line in lines
        if line.match("^$")
            continue
        if line.indent > cindent
            stack.push(block)
            let block = []
            let cindent = line.indent
        if line.indent == cindent
            block.push(line)
        if line.indent < cindent
            while not stack.empty()
                " block = sort(block) "?
                let prevblock = stack.pop()
                if prevblock.indent < block.indent
                    prevblock.push(block)
                    let block = prevblock
                if prevblock.indent == block.indent
                    stack.push(prevblock)
            let stack.push(block)
            let cindent = line.indent
```
