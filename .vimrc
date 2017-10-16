" Setup coloring and visual presentation
set t_Co=256
set confirm
set number
set encoding=utf-8
set listchars=tab:→\ ,trail:·,space:·
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
set term=xterm-256color
syntax enable
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized

" Session management
"set ssop-=options    " do not store global and local values in a session
"set ssop-=folds      " do not store folds
let g:session_autosave = 'yes'
let g:session_autoload = 'yes' " reload 'default' on startup
" If you only want to save the current tab page:
"set sessionoptions-=tabpages
" " If you don't want help windows to be restored:
"set sessionoptions-=help
" Don't save hidden and unloaded buffers in sessions.
"set sessionoptions-=buffers

" Setup shell (bash)
set shell=/bin/bash
let $BASH_ENV = "~/.bash_aliases"

" Syntax highlightning fixes
au FileType perl set filetype=prolog

" Initialize Pathogen
execute pathogen#infect()
filetype plugin indent on

" Initialize Gundo
let g:gundo_return_on_revert=0

" Initialize wintabs
let g:wintabs_ui_buffer_name_format = '%n:%t'
let g:wintabs_ui_modified = '*'
let g:wintabs_ui_readonly = '!'
let g:wintabs_ui_sep_rightmost = ' '

" Allow saving of files as sudo when forgot to start vim using sudo
cmap w!! w !sudo tee > /dev/null %

" Use Ctrl-Alt-Left|Right to switch buffer
nnoremap <C-A-Right> :WintabsNext<CR>
nnoremap <C-A-Left> :WintabsPrevious<CR>
nnoremap <C-W> :bd<CR>
"nnoremap <C-S-W> :WintabsOnly<CR>

" Use Shift-Tab to dedent
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Use Ctrl-L to show/hide line numbers
nnoremap <C-L> :set nu!<CR>

" Use Ctrl-D to duplicate row(s)
nnoremap <C-D> :y<CR>mmp`m
inoremap <C-D> <Esc>:y<CR>p==gi
vnoremap <C-D> yP

" Disable arrow keys
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
vnoremap <Up> <Nop>
vnoremap <Down> <Nop>
vnoremap <Left> <Nop>
vnoremap <Right> <Nop>

" Use <Alt-Arrows> to move lines around
" Follwoing is hack for terminology sending '<Esc>j' instead of '<Alt-j>'
" Reference: https://stackoverflow.com/questions/7501092/can-i-map-alt-key-in-vim
execute "set <A-j>=\ej"
execute "set <A-k>=\ek"
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Use <F5> to execute current file
nnoremap <F5> :!./%<CR>

" Use <F10> to show hidden characters
nnoremap <F10> :set list!<CR>
inoremap <F10> <Esc>:set list!<CR>==gi

" Use <F12> as Gundo toggle key
nnoremap <F12> :GundoToggle<CR>

