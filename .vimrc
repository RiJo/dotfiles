syntax on

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

" Disable arrow keys
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" Ability to move around in insert mode
" TODO: breaks backspace in insert mode..
"inoremap <C-j> <Down>
"inoremap <C-k> <Up>
"inoremap <C-h> <Left>
"inoremap <C-l> <Right>

" Easier to move lines around
nnoremap <S-j> :m .+1<CR>==
nnoremap <S-k> :m .-2<CR>==
inoremap <S-j> <Esc>:m .+1<CR>==gi
inoremap <S-k> <Esc>:m .-2<CR>==gi
vnoremap <S-j> :m '>+1<CR>gv=gv
vnoremap <S-k> :m '<-2<CR>gv=gv
" TODO: terminology doesn't send 8-bit alt-code..
"nnoremap <Esc>j :m .+1<CR>==
"nnoremap <Esc>k :m .-2<CR>==
"inoremap <Esc>j <Esc>:m .+1<CR>==gi
"inoremap <Esc>k <Esc>:m .-2<CR>==gi
"vnoremap <Esc>j :m '>+1<CR>gv=gv
"vnoremap <Esc>k :m '<-2<CR>gv=gv

