function! WorkspaceHookBefore()
 
 " $CXX -E -x c++ - -v < /dev/null
 set path+=/usr/include/c++/10/**
 set path+=/usr/bin/../lib/gcc/x86_64-linux-gnu/10/../../../../include/x86_64-linux-gnu/c++/10/**
 set path+=/usr/bin/../lib/gcc/x86_64-linux-gnu/10/../../../../include/c++/10/backward/**
 set path+=/usr/local/include/**
 set path+=/usr/lib/llvm-11/lib/clang/11.0.1/include/**
 set path+=/usr/include/x86_64-linux-gnu/**
 set path+=/usr/include/**

endfunction

function! WorkspaceHookAfter()
  set foldmethod=manual
  " syntax enable
  " filetype plugin indent on
  " set foldmethod=syntax

  " Mappings to move lines
  nnoremap <A-j> :m .+1<CR>==
  nnoremap <A-k> :m .-2<CR>==
  inoremap <A-j> <Esc>:m .+1<CR>==gi
  inoremap <A-k> <Esc>:m .-2<CR>==gi
  vnoremap <A-j> :m '>+1<CR>gv=gv
  vnoremap <A-k> :m '<-2<CR>gv=gv
  
  " Alternative tab navigation
  nnoremap th  :tabfirst<CR>
  nnoremap tk  :tabnext<CR>
  nnoremap tj  :tabprev<CR>
  nnoremap tl  :tablast<CR>
  nnoremap tt  :tabedit<Space>
  nnoremap tn  :tabnext<Space>
  nnoremap tm  :tabm<Space>
  nnoremap td  :tabclose<CR>

  " autocmd BufEnter * if (bufname("#") =~ "term://" && bufname("%") !~ "term://") | b# | endif
  " autocmd BufEnter * if (bufname("#") =~ "NvimTree" && bufname("%") !~ "NvimTree") | b# | endif
  " autocmd BufEnter * if (bufname("#") =~ "NERD_tree" && bufname("%") !~ "NERD_tree") | b# | endif
  " autocmd BufEnter * if (bufname("#") =~ "__Tagbar__" && bufname("%") !~ "__Tagbar__") | b# | endif
endfunction

