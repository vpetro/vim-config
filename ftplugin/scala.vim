" set tabstop for scalacode
set tabstop=2
set shiftwidth=2


" send compile command to default tmux pane
function! SendSbtCommand(command)
    set filetype=text
    call SendToTmux(a:command . "\n")
    set filetype=scala
endfunction

" setup the compile command
nmap <leader>ew :wall \| silent! call SendSbtCommand("c")<cr>
" setup the test command
nmap <leader>et :wall \| silent! call SendSbtCommand("t")<cr>
" setup the run command
nmap <leader>er :wall \| silent! call SendSbtCommand("r")<cr>

nmap \E  :EnsimeStart<cr>
nmap \ee :EnsimeConnect<cr>
nmap \ea :EnsimeTypecheckAll<cr>
nmap \ef :EnsimeTypecheckFile<cr>
nmap \et :EnsimeTypeAtPoint<cr>
vmap \et :<C-U>EnsimeTypeOfSelection<cr>
nmap \ed :EnsimeSymbolAtPoint<cr>
nmap \eu :EnsimeUsesOfSymbolAtPoint<cr>

function! s:ReplHandler(job_id, data, event)
    if a:event == 'exit'
        if exists("g:repl_terminal_id") && (g:repl_terminal_id == a:job_id)
            unlet g:repl_terminal_id
        endif
    endif
endfunction

function! OpenREPL(repl_name)
    let s:repl_command = ""
    if a:repl_name ==# "spark"
        let s:repl_command = "SPARK_CLASSPATH=$HOME/.ivy2/cache/org.postgresql/postgresql/jars/postgresql-9.4-1204-jdbc42.jar spark-shell"
    elseif a:repl_name ==# "console"
        let s:repl_command = "/Users/petrov/bin/sbt console"
    elseif a:repl_name ==# "sbt"
        let s:repl_command = "/Users/petrov/bin/sbt"
    else
        let s:repl_command = "scala"
    endif

    call RestartREPL()
endfunction

function! RestartREPL()
    call StopREPL()
    call StartREPL()
endfunction

function! StartREPL()
    botright split enew
    let g:repl_terminal_id = termopen(s:repl_command)
    let g:repl_buffer_name = bufname('%')
endfunction

function! StopREPL()
    if exists("g:repl_terminal_id") 
        if jobpid(g:repl_terminal_id) != 0
            call jobstop(g:repl_terminal_id)
            unlet g:repl_terminal_id
            execute 'bwipeout! ' . g:repl_buffer_name
            unlet g:repl_buffer_name
        else
            unlet g:repl_terminal_id
            unlet g:repl_buffer_name
        endif
    endif
endfunction

function! PasteScala(lines)
    if !exists("g:repl_terminal_id")
        call OpenREPL()
    endif
    let toPaste = substitute(a:lines, "\n", "", "g")
    call jobsend(g:repl_terminal_id, add([':paste', toPaste], ''))
endfunction

function! SplitWithREPL()
    if exists("g:repl_terminal_id")
        only
        execute "botright split " . g:repl_buffer_name
    endif
endfunction

command! -nargs=1 RL :call OpenREPL(<f-args>)
nnoremap <A-r> :silent! call RestartREPL()<CR>
nnoremap <A-k> :silent! call StopREPL()<CR>
" send current line
nnoremap <A-p> ^v$"*y \| :silent! call PasteScala(@*)<CR>
" send current visual selection
vnoremap <A-p> "*y \| :silent! call PasteScala(@*)<CR>
" re-send the last selection
nnoremap <A-l> gv"*y \| :silent! call PasteScala(@*)<CR>
