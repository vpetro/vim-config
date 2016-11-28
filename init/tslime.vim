" connect tslime to the second pane of the first window in the current tmux
" session
let g:tmux_sessionname = substitute(system("tmux display-message -p '#S'"), '\n', '', '')
let g:tmux_windowname = 1
let g:tmux_panenumber = 2
