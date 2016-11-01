" Setup coloring and visual presentation
set t_Co=256
set number
syntax enable
let g:solarized_termcolors=256
set background=dark
colorscheme solarized

" Allow saving of files as sudo when forgot to start vim using sudo
cmap w!! w !sudo tee > /dev/null %

" Disable arrow keys
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
vnoremap <Up> <Nop>
vnoremap <Down> <Nop>
vnoremap <Left> <Nop>
vnoremap <Right> <Nop>

" Ability to move around in insert mode w/o arrow keys
inoremap <S-j> <Down>
inoremap <S-k> <Up>
inoremap <S-h> <Left> " Note: map <C-h> breaks backspace
inoremap <S-l> <Right>

" Easier to move lines around
nnoremap <Esc>j :m .+1<CR>==
nnoremap <Esc>k :m .-2<CR>==
inoremap <Esc>j <Esc>:m .+1<CR>==gi
inoremap <Esc>k <Esc>:m .-2<CR>==gi
vnoremap <Esc>j :m '>+1<CR>gv=gv
vnoremap <Esc>k :m '<-2<CR>gv=gv

