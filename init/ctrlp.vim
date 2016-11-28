let g:ctrlp_match_window_reversed = 0
let g:ctrlp_max_height = 10
let g:ctrlp_working_path_mode = 0
let g:ctrlp_dotfiles = 0
let g:ctrlp_extensions = ['line']
let g:ctrlp_match_func = {'match': 'pymatcher#PyMatch'}
" let g:ctrlp_lazy_update = 350
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_max_files = 0

if executable("ag")
    set grepprg=ag\ --nogroup\ --nocolor
    let g:ctrlp_user_command = 'ag %s -i --nocolor --nogroup -p ~/.aignore --ignore ''.git'' --ignore ''.DS_Store'' --ignore ''node_modules'' --ignore "**/*.json" --ignore "**/*.png" --hidden -g ""'
endif

let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(ensime|git|hg|svn)$',
  \ 'scala':  '\v[\/]*(target)$',
  \ 'file': '\v\.(json|png|gif|jpg||exe|so|dll|snb)$'
  \ }

" nnoremap <leader>t :CtrlP<cr>
" nnoremap <leader>l :CtrlPLine %<cr>
" nnoremap <localleader>t :CtrlPTag<cr>
" nnoremap <localleader>ct :CtrlPTag<cr><C-\>r/

