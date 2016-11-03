# Notes by myself
Following is a collection of tips and tricks using vim.

## General

### Replace <Esc>
`Ctrl-C`

### Marks
Add: `<m[a-zA-Z>`
Goto: ``[a-zA-Z>`

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

## Execute external command
`:! [command]`

To get output to the current window:
`:.! [command]`

## To get output to the current window on a new line:
`:r!`

## Scroll the screen to make this line appear in center
`zz`

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
`"*p`
`"+p`
