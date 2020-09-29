# vim-todo

A plugin designed to simplify the process of task management. It enables the 
user to quickly edit tasks and create new ones so the focus can be targeted 
towards the actual task and not everything surrounding it. Together with the 
keybindings which speed up the process of creating and editing tasks, the user 
is provided with a set of commands to organize the todo-document without the 
struggle of having to move everything around themselves. 

In addition to this the user is provided with a folding method to quickly show 
or hide tasks, custom highlighting to easily differentiate between the different
kinds of tasks.

Read on to see how to configure and what else is provided.

## Philosophy 

When I created this plugin I wanted a simple way of managing my tasks without
having to spend most of my time managing the task-management. By packing a few
keybindings together with a syntax file, folding file and some commands, I 
suddenly had a complete setup for configuring my tasks easily.

## Installation

if you are using a plugin manager then add `vim-todo` as you would any other
plugin. Otherwise clone the repository from Github and place it where your
other plugins are placed.

```vim
" Vundle
Plugin 'mortepau/vim-todo'

" vim-plug
Plug 'mortepau/vim-todo'

" Neobundle
Neobundle 'mortepau/vim-todo'

" Dein
call dein#add('mortepau/vim-todo')
```
```sh
# Vim 8 native package loading
git clone https://github.com/mortepau/vim-todo.git ~/.vim/pack/my-packages/start/vim-todo

# Pathogen (vim)
git clone https://github.com/mortepau/vim-todo.git ~/.vim/bundle/vim-todo

# Pathogen (Neovim)
git clone https://github.com/mortepau/vim-todo.git ~/.config/nvim/bundle/vim-todo
```

## Terminology

To simplify the explanation a few terms are useful. This paragraph will refer
to the following code block when using line #.

```
[/] - Header
[ ] - Parent and header
  [ ] - Child and parent
    [X] - Child 1
    ![ ] - Child 2

  [ ] - Orphan
```

`task`: A task is a line which contains some level of indentation (possibly none)
and either of the templates in `g:todo_completion_templates` before any text.
i.e. `[X] - A completed task`.

`task template`: Either of the strings found in `g:todo_completion_templates`.
i.e. `[/] - ` from line 1.

`task text`: The task string without the task template. i.e. `Header` from line 1.

`parent`: A task which has children. i.e. line 2.

`child`: A task which has a parent. Cannot be a header-task. i.e. line 3.

`orphan`: A task with no parent, but should have. i.e. line 7.

`header`: A task which has no parent and no indentation. i.e. line 1

`open`: A task that is incomplete and/or has not been started on. i.e. line 2.  
(Default template: `g:todo_completion_templates.open = "[ ] - "`)

`partial`: A task that has been progressed on, but not completed. i.e. line 1.  
(Default template: `g:todo_completion_templates.partial = "[/] - "`)

`closed`: A completed task. i.e. line 4.  
(Default template: `g:todo_completion_templates.closed = "[X] - "`)

`active`: A task which is currently in progress. i.e. line 5.  
(Default template: `g:todo_completion_templates.active  = "!"`)

## Keybindings

### `o`

Creates a new `task` below the current `task`. The `task template` is given 
by `g:todo_completion_templates.open`. The new `task` is given the
indent of the current `task` except if the current `task` has any `children` then
it is given an extra level of indentation.

Examples:

When the current `task` has no children: 
```todo
Before:
[ ] - A task|
[ ] - Another task

After:
[ ] - A task
[ ] - |
[ ] - Another task
```

When the current `task` has children: 
```todo
Before:
[ ] - A task|
  [ ] - Another task

After:
[ ] - A task
  [ ] - |
  [ ] - Another task
```

### `O`

Creates a new `task` above the current `task`. The `task template` is given by
`g:todo_completion_templates.open`. The new `task` is given the indent
of the current `task`.

Examples:

```todo
Before:
[ ] - A task|
[ ] - Another task

After:
[ ] - |
[ ] - A task
[ ] - Another task
```

### `<CR>`

The `<CR>` keybinding has different functionality based on the current mode:

Normal:

Toggle the completion of the current `task`. If 
`g:todo_enable_partial_completion` is set to true the behaviour is as follows:
```
open -> partial
partial -> closed
closed -> open
```
If `g:todo_enable_partial_completion` is set to false the behaviour is as 
follows:
```
open -> closed
closed -> open
```

Examples:

When `g:todo_enable_partial_completion = v:true`:
```todo
Before:
[ ] - A task|

After:
[/] - A task|
```

When `g:todo_enable_partial_completion = v:false`:
```todo
Before:
[ ] - A task|

After:
[X] - A task|
```

Insert:

Insert a new `task` either above or below the current one based on cursor 
position.

Examples:

Cursor before `task template`:
```todo
Before:
|[ ] - A task

After:
[ ] - |
[ ] - A task
```

Cursor after `task template`, but before `task text`:
```todo
Before:
[ ] - |A task

After:
[ ] - |
[ ] - A task
```

Cursor inside `task text`:
```todo
Before:
[ ] - A |task

After:
[ ] - A |
[ ] - task
```

Cursor after `task text`:
```todo
Before:
[ ] - A task|

After:
[ ] - A task
[ ] - |
```

### `<SPACE>`

Toggle the `active` status of the current `task`. Does not make a `closed task`
`active`.

Examples:

When the current `task` is not `active`
```todo
Before:
[ ] - A task|

After:
![ ] - A task|
```

When the current `task` is `active` and not `closed`:
```todo
Before:
![ ] - A task|

After:
[ ] - A task|
```

When the current `task` is `closed`:
```todo
Before:
[X] - A task|

After:
[X] - A task|
```

### `<TAB>`

Indent the current `task` one level.

Example:
```todo
Before:
[ ] - A task
[ ] - Another task|
  [ ] - A subtask

After:
[ ] - A task
  [ ] - Another task|
  [ ] - A subtask
```

### `g<TAB>`

Indent the current `task` one level, and do the same for its `children`.

Example:
```todo
Before:
[ ] - A task
[ ] - Another task|
  [ ] - A subtask

After:
[ ] - A task
  [ ] - Another task|
    [ ] - A subtask
```

### `<S-TAB>`

Deindent the current `task` one level.

Example:
```todo
Before:
[ ] - A task
  [ ] - Another task|
  [ ] - A subtask

After:
[ ] - A task
[ ] - Another task|
  [ ] - A subtask
```

### `g<S-TAB>`

Deindent the current `task` one level, and do the same for its `children`.

Example:
```todo
Before:
[ ] - A task
  [ ] - Another task|
    [ ] - A subtask

After:
[ ] - A task
[ ] - Another task|
  [ ] - A subtask
```

## Filetype

The files which are considered to be a todo-file are following one of the
following patterns for their filename
```regex
\v\C^(.*\.)?(todo|Todo|TODO)$
```

Examples of matching filenames:
```
todo
Todo
TODO
.todo
.Todo
.TODO
name.Todo
name.TODO
name.subname.todo
```

## Commands

### `TodoSort`

Sort all `tasks` based on the order in `g:todo_sorting_priority`. If a `task` 
has a `parent` it will only be sorted among its `parent`'s `children` and not
among all `tasks`.

Examples:

Given `g:todo_sorting_priority = ['active', 'open', 'closed']`

```todo
Before:
[ ] - Header
  [X] - Subtask
  [ ] - Another child
    [ ] - Open task
    [X] - Closed task
    [ ] - Another open task

![ ] - Another header
  [X] - Closed child
  [ ] - Open
    [ ] Open 2

After:
![ ] - Another header
  [ ] - Open
    [ ] Open 2
  [X] - Closed child

[ ] - Header
  [ ] - Another child
    [ ] - Open task
    [ ] - Another open task
    [X] - Closed task
  [X] - Subtask
```

### `TodoConvert`

Convert all invalid `tasks` in the file to valid ones. Valid means if the 
`task template` for the `task` is present in `g:todo_completion_templates`.
`TodoConvert` accepts either 0 or multiple arguments in the form of 
`key "value"`. If it is called with 0 arguments the user is prompted to input 
the `value` for each `key`.

Examples

If called using `TodoConvert` the user is prompted as shown below
```
Enter template for 'open':( ) - 
Enter template for 'closed':(x) - 
Enter template for 'active':a
```

If called using `TodoConvert open "( ) - " closed "(x) - " active "a"` the
user is not prompted with anything

Either way the result is as follows:
```todo
Before:
( ) - Invalid format
  (x) - Invalid format again
  a( ) - Invalid active format

After:
[ ] - Invalid format
  [X] - Invalid format again
  ![ ] - Invalid active format
```

### `TodoShow`

Show virtual text with additional information about a `task`
The information shown is controlled by `g:todo_enable_creation_date`,
`g:todo_enable_update_date` and `g:todo_enable_percentage_completion`.
To use virtual text `g:todo_enable_virtual_text` must be set to true.

### `TodoHide`

Hide the virtual text with additional information about a `task`

## Syntax

The syntax file adds a different highlight to each kind of `task`. 
It also conceals the `task template` on all lines except the currently active 
one to simplify reading a `task`.

<!-- INCLUDE SCREENSHOT -->

## Folding

The folding is made so that it is possible to hide individual `tasks` and its
`children` without affecting the other `tasks`. There is no need to define
specific fold markers, it should work out-of-the-box.

<!-- INCLUDE SCREENSHOT -->

If you are unfamiliar with folding check out the help page for it: `:h usr_28.txt`.

## Configuration

### g:todo_auto_update_tasks

Automatically update a `task`'s `parent` and `children` when its status or 
completion is changed.

Default: `v:true`

### g:todo_auto_update_virtual_text

Automatically update the virtual text, without calling `TodoShow`.

Default: `v:true`

### g:todo_completion_templates

The templates used for each kind of `task`.

Default: 
```vim
{
    'open':    '[ ] - ',
    'closed':  '[X] - ',
    'partial': '[/] - ',
    'active':  '!',
}
```

### g:todo_enable_active_status

Enables the usage of active `tasks`.

Default: `v:true`

### g:todo_enable_auto_sort

Enables the automatic sorting of `tasks` after an update.

Default: `v:true`

### g:todo_enable_conceal

Enables concealing of `task template`.

Default: `v:true`

### g:todo_enable_creation_date

Enables showing the creation time of each `task`.

Default: `v:true`

### g:todo_enable_default_bindings

Enables the use of the default keybindings.

Default: `v:true`

### g:todo_enable_partial_completion

Enables the usage of partially completed `tasks`.

Default: `v:true`

### g:todo_enable_percentage_completion

Enables showing the current completion percentage for each `task`.

Default: `v:true`

### g:todo_enable_update_date

Enables showing the last updated time of each `task`.

Default: `v:true`

### g:todo_enable_virtual_text

Enables the use of virtual text.  
(Neovim only as it depends on nvim_buf_set_virtual_text)

Default: `v:true`

### g:todo_inline_template

Defines the word to use when inserting a new `task template` on an empty line.

Default: `"new"`

### g:todo_sorting_priority

Defines the priority the different kinds of `tasks` has when sorting.

Default:
```vim
["active", "open", "partial", "closed"]
```

### g:todo_task_colors

Defines which highlight groups to use for highlighting the different.
`tasks`.

Default:
```vim
{
    'active':  'Identifier',
    'closed':  'Comment',
    'header':  'Statement',
    'open':    'Ignore',
    'partial': 'Type',
}
```

### g:todo_virtual_text_colors

Defines which color to assign to the different virtual text elements.  
`green` defines which color to use for `tasks` that are 100% completed, 
`yellow` for `tasks` that are between 33% and 80%, and `red` for `tasks` below
33%. Creation date is assigned the color in `creation` and Update date is
assigned the color in `update`.

Default:

```vim
{
   'creation': 'DarkBlue',
   'green':    'DarkGreen',
   'red':      'DarkRed',
   'update':   'DarkCyan',
   'yellow':   'DarkYellow',
}
```

## License
MIT License

Copyright (c) 2020 Morten Paulsen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
