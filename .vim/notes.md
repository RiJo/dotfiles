# Notes by myself
Following is a collection of tips and tricks using vim.

## General

### Open at specific line
`vim <file> +42`

### Goto line
`:42`

### Movement
Next page: `<Ctrl-F>`
Previous page: `<Ctrl-B>`
Top of screen: `H`
Middle of screen: `M`
Bottom of screen: `L`
Scroll down (half page): `<Ctrl-D>`
Scroll up (half page): `<Ctrl-U>`

### Insert
Current position: `i` or `I`
Last on line: `a` or `A`
New line: `o` or `O`

### Delete character
`x`

### Replace character:
`r`

### Skip word
Jump to start: `w`
Jump to end: `e`

### Replace <Esc>
`Ctrl-C`

### Buffers
List buffers: `:buffers`
Goto buffer: `:b <id or name>`
Delete current one: `:bd`
Close all but current: `:on`

### Marks
Upper-case are global and lower-case are per buffer.

List: `:marks`
Add: `<m[a-zA-Z>`
Goto: `[a-zA-Z>`

### Undo/redo
Undo: `u`
Redo: `<Ctrl>-r`

### Open other file
`:e <file>`

## Custom

### Indent/dedent
Indent: `<Tab>`
Dedent: `<Shift-Tab>`

### Move line(s)
`<Alt-hjkl>`

### Duplicate line(s)
`<Ctrl-d>`

### Toggle Gundo.vim
`<F12>`

# What are the dark corners of Vim your mom never told you about?
<http://stackoverflow.com/questions/726894/what-are-the-dark-corners-of-vim-your-mom-never-told-you-about>

## Write as sudo
`:w !sudo tee %`

## Execute current file
`:ec`

## Execute external command
`:! <command>`

To get output to the current window:
`:.! <command>`

## To get output to the current window on a new line:
`:r!`

## Scroll the screen to make this line appear in center
`zz` or `z.`

Sibling commands:
`zt`
`zb`

## Move back and forth in changelist:
`g;`
`g,`

## Goto last edited line:
`'.`

...and position:
``.`

# Some Vim tips
<http://pastebin.com/BGGkBmVw>

## Paste from clipboard
To test if your version of vim is compiled with the clipboard, do `vim --version | grep clipboard` and you should have the following arguments: `+clipboard` and `+xterm_clipboard`.

To resolve this on Arch Linux: install `gvim` package instead of `vim` which ships with the vim command compiled to support clipboard.

Paste from PRIMARY ("middle-click"): `"*p`
Paste from clipboard: `"+p`
