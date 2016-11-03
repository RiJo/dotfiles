" Setup coloring and visual presentation
set t_Co=256
set number
set cursorline
syntax enable
let g:solarized_termcolors=256
let g:solarized_termtrans=1
set background=dark
colorscheme solarized

" Initialize Pathogen
execute pathogen#infect()
filetype plugin indent on

" Initialize Gundo
let g:gundo_return_on_revert=0

" Allow saving of files as sudo when forgot to start vim using sudo
cmap w!! w !sudo tee > /dev/null %

cmap ec !./%

" Use Shift-Tab to dedent
inoremap <S-Tab> <C-D>
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Use Ctrl-D to duplicate row(s)
nnoremap <C-D> :y<CR>P
inoremap <C-D> <Esc>:y<CR>Pi
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
nnoremap <Esc>j :m .+1<CR>==
nnoremap <Esc>k :m .-2<CR>==
inoremap <Esc>j <Esc>:m .+1<CR>==gi
inoremap <Esc>k <Esc>:m .-2<CR>==gi
vnoremap <Esc>j :m '>+1<CR>gv=gv
vnoremap <Esc>k :m '<-2<CR>gv=gv

" Use <F12> as Gundo toggle key
nnoremap <F12> :GundoToggle<CR>

