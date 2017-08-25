" fold region for headings
syn region mkdHeaderFold
    \ start="^\s*\z(#\+\)"
    \ skip="^\s*\z1#\+"
    \ end="^\(\s*#\)\@="
    \ fold contains=TOP

" fold region for lists
syn region mkdListFold
    \ start="^\z(\s*\)\*\z(\s*\)"
    \ skip="^\z1 \z2\s*[^#]"
    \ end="^\(.\)\@="
    \ fold contains=TOP

syn sync fromstart
setlocal foldmethod=syntax
setlocal foldlevelstart=2

nmap <space>1 0i# <esc>
nmap <space>2 0i## <esc>
nmap <space>3 0i### <esc>
nmap <space>4 0i#### <esc>

set spell
