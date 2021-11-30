
set foldmethod=expr
set foldexpr=MarkdownFolding(v:lnum)

function! MarkdownFolding(lnum)
  if getline(a:lnum) =~? '\v^\s*$'
      return '-1'
  endif

  return '0'
endfunction

function! IndentLevel(lnum)
  let i = 0
  let length = len(getline(lnum))

  while i <= length
  endwhile
endfunction

"setlocal makeprg=/Users/petrov/bin/make_md\ %:p\ %:p:r.ipynb
set makeprg=pandoc\ \-s\ \-o\ /tmp/output.html\ \-t\ html5\ \-c\ /Users/petrov/code/pandoc-css/github.css\ %

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

" markdown boxes
nnoremap <buffer> <Leader>e 0f i [ ]<esc>
nnoremap <buffer> <Leader>E 0f[lrx<esc>

" headings, no first level because it is easy enough
iabbrev ,2 ##
iabbrev ,3 ###
iabbrev ,4 ####

nnoremap <buffer> <leader>1 I# <esc>
nnoremap <buffer> <leader>2 I## <esc>
nnoremap <buffer> <leader>3 I### <esc>
nnoremap <buffer> <leader>4 I#### <esc>

nnoremap <silent> ]] /#\+\s<cr>:nohl<cr>
nnoremap <silent> [[ ?#\+\s<cr>:nohl<cr>


iabbrev ,t - TODO: 

" all writing
iabbrev <buffer> teh the
iabbrev <buffer> adn and

" writing at work
iabbrev <buffer> opp opportunity
iabbrev <buffer> sub subscription
iabbrev <buffer> nab enablement
iabbrev <buffer> gag engagement
iabbrev <buffer> app application
iabbrev <buffer> apps applications
iabbrev <buffer> mss microservice
iabbrev <buffer> msss microservices

