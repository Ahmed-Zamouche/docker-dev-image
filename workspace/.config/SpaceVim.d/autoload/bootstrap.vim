let g:workspace_vimrc = getcwd() . '/.vimrc'
if filereadable(g:workspace_vimrc)
  execute 'source' g:workspace_vimrc
endif

function! bootstrap#before() abort
  " let g:neomake_c_enabled_makers = ['clang']
  inoremap kj <Esc>
  tnoremap <Esc> <C-\><C-n>
  silent! tunmap <M-left>
  silent! tunmap <M-right>
  if exists('*WorkspaceHookBefore')
    call WorkspaceHookBefore()
  endif
endfunction

function! bootstrap#after() abort
  " iunmap kj
  if exists('*WorkspaceHookAfter')
    call WorkspaceHookAfter()
  endif
endfunction
