" searching with TheSilverSearcher and Ag.vim
function! AgCurrentFileType(currentWord)
    execute("Ag! --" . &filetype . " " . a:currentWord)
endfunction

" prepare to search for something random
nmap <leader>aa :Ag!<space>
" search everything for the current <cword>
nmap <leader>aw :Ag! <cword><cr>
" search with current filetype for the curent <cword>
nmap <leader>at :call AgCurrentFileType("<C-R><C-W>")<cr>
" search with the current filetype for the current <CWORD>
nmap <leader>aT :call AgCurrentFileType("<C-R><C-A>")<cr>

