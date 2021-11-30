setlocal spell spelllang=en_gb

setlocal linebreak
setlocal nonumber

setlocal textwidth=0
setlocal colorcolumn=0

setlocal wrap
setlocal wrapmargin=0

nnoremap <leader>m :silent! make<cr>

nnoremap <buffer> k gk
nnoremap <buffer> j gj

" fix the last misspelled word with the first suggestion
inoremap <C-l> <c-g>u<Esc>[s1z=`]a<c-g>u

" nnoremap <buffer> <Leader>e 0f i [ ]<esc>
" nnoremap <buffer> <Leader>E 0f[lrx<esc>

" headings, no first level because it is easy enough
iabbrev ,2 ==
iabbrev ,3 ===
iabbrev ,4 ====

nnoremap <buffer> <leader>1 I= <esc>
nnoremap <buffer> <leader>2 I== <esc>
nnoremap <buffer> <leader>3 I=== <esc>
nnoremap <buffer> <leader>4 I==== <esc>

nnoremap <silent> ]] /#\+\s<cr>:nohl<cr>
nnoremap <silent> [[ ?#\+\s<cr>:nohl<cr>


iabbrev ,t - TODO: 

" all writing
iabbrev <buffer> teh the
iabbrev <buffer> adn and

" writing at work
iabbrev <buffer> eng engineer
iabbrev <buffer> opp opportunity
iabbrev <buffer> sub subscription
iabbrev <buffer> nab enablement
iabbrev <buffer> gag engagement
iabbrev <buffer> app application
iabbrev <buffer> apps applications
iabbrev <buffer> mss microservice
iabbrev <buffer> msss microservices

set makeprg=asciidoctor\ \-o\ /tmp/output.html\ %
