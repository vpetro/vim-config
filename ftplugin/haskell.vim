setlocal expandtab
setlocal tabstop=2
setlocal softtabstop=2
setlocal shiftwidth=2

let g:syntastic_haskell_hdevtools_args = '-g-isrc -g-Wall'
" colorscheme distinguished

nnoremap <buffer> <localleader>t :HdevtoolsType<CR>
nnoremap <buffer> <silent> <localleader>T :HdevtoolsClear<CR>
nnoremap <buffer> <leader>r :call Send_to_Tmux(':load ' . expand('%:b') . " \n")
