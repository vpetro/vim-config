" Petro Verkhogliad <vpetro@gmail.com>
" last modification: 2016-04-01

execute pathogen#infect()
Helptags
syntax on
filetype plugin indent on


" compatibility {
set t_Co=256
set hidden
set nolazyredraw
" set termguicolors
" }

" indenting {
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set list listchars=tab:»·,trail:·,extends:·,precedes:·,
highlight SpecialKey ctermfg=235
" }

" scrolling {
set nowrap
set scrolloff=4
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>
" }

" searching {
set ignorecase
set smartcase
set incsearch
set hlsearch
nmap <silent> <C-n> :noh<CR>
nmap n nzz
nmap N Nzz

nmap * *zz
nmap # #zz
nmap g* g*zz
nmap g# g#zz
" }

" window movement and balancing {
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
" nnoremap <BS>  <C-w>h
nnoremap <C-l> <C-w>l
" move from the neovim terminal window to somewhere else
tnoremap <C-h> <C-\><C-n><C-w>h
tnoremap <C-j> <C-\><C-n><C-w>j
tnoremap <C-k> <C-\><C-n><C-w>k
tnoremap <C-l> <C-\><C-n><C-w>l
tnoremap <C-]> <C-\><C-n>


" equalize the windows when vim is resized
autocmd VimResized * :wincmd =
" }

" misc {
set showmatch
" limit the size of the preview window
set previewheight=20
" limit the popup menu height to 15
set pumheight=15
set backspace=2
set whichwrap+=<,>,h,l
set iskeyword=~,@,48-57,_,192-255
set history=1000

set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.cmi,.cmo,.cmx,.cmxa,.exe,.ho,.hi,.bc,.out,.annot,.spot
set wildmenu
"set wildignore+=*/.hg/*,*/.svn/*,*/bin/*,*/images/*
set wildignore+=*/.hg/*,*/.svn/*,*/images/* " temp fix for fzf
set wildignore+=*/target/*,*/.idea/*
set wildignore+=*.dll,*.exe
set wildignore+=*.o,*.obj,*.class,*.pyc,*.log,*.pidb,*.jar,*.class
set wildignore+=*.aux,*.bbl,*.blg,*.fdb_latexmk,*.bst,*.pdf,*.png,*.jpg,*.gif
set wildignore+=*.json,*.bson
set wildignore+=*.jar
set wildignore+=*.snb

if has("eval")
    runtime! macros/matchit.vim
endif

" }

" dont show the line numbers or relative numbers {
set nonumber
set norelativenumber
set ruler
" }

" auto-reading and auto-writing {
" set to auto read when a file is changed from the outside
set autoread

" save the file when vim loses focus. useful.
au FocusLost * :wa

" set the the dir where to store the swap files.
set noswapfile nowritebackup nobackup

" set encoding
" set enc=utf-8
set fileformats=unix,dos,mac
" }

" error bell and status line {
set noerrorbells
set novisualbell
set visualbell t_vb=
set laststatus=2
set statusline=%<%f\ %h%w%m%r%y%=B:%n\ L:%l/%L\ G:%{fugitive#statusline()}
" }

" set up leaders {
let mapleader = "\<Space>"
" let g:mapleader = "\<Space>"
" let localleader = " "
" let maplocalleader = " "
" }

" set colorscheme and colorcolumn {
set background=dark
set colorcolumn=79
colorscheme petro
" }

" normal mode mappings for all {
nmap <leader>m :make<CR>
nmap <leader>sp :setlocal spell! spelllang=en<CR>
noremap W :w<cr>

" faster quiting and saving
nmap <leader>q :q!<cr>
nmap <leader>w :w!<cr>

nmap <leader>ev :vsplit ~/.config/nvim/init.vim<cr>
nmap <leader>sv :source ~/.config/nvim/init.vim<cr>

" Pull word under cursor into LHS of a substitute
nmap <leader>z :%s#\<<c-r>=expand("<cword>")<cr>\>#
" run rsync
" nmap <space>rr :execute ":!rsr pg"<cr>
" }

" insert mappings for all {
ino jj <esc>
cno jj <C-c>
" nmap <space><space> <esc>
" vmap <space><space> <esc>
" imap <space><space> <esc>
" }

" quickfix {
nmap <leader>co :botright cwindow<cr>
nmap <leader>cq :cclose<cr>
nmap <leader>cn :cnext<cr>
nmap <leader>cl :clast<cr>
nmap <leader>cp :cprevious<cr>

" close the quickfix window if it it is the only remaining open window
autocmd BufEnter * if (winnr('$') == 1 && &ft ==# 'qf') | q | en
autocmd BufLeave * set colorcolumn=
autocmd BufEnter * set colorcolumn=79

" }

" load configuration for plugins {
source ~/.config/nvim/init/folding.vim
source ~/.config/nvim/init/fzf.vim
source ~/.config/nvim/init/ag.vim
source ~/.config/nvim/init/tagbar.vim
source ~/.config/nvim/init/nerdcommenter.vim
source ~/.config/nvim/init/fugitive.vim
source ~/.config/nvim/init/ultisnips.vim
" }
"

" quick access to dumped pane text
nmap <leader>ep :vsplit ~/.tmux/pane.out<cr>
nmap cl :execute "normal! G?\\[ctig_portal\\]\<cr>jVggd"

let g:rainbow_active = 1

set ttimeout
set ttimeoutlen=0

call textobj#user#plugin('line', {
\   '-': {
\     'select-a-function': 'CurrentLineA',
\     'select-a': 'al',
\     'select-i-function': 'CurrentLineI',
\     'select-i': 'il',
\   },
\ })

function! ToggleMaximixed()
  if !exists('g:window_maximized') || g:window_maximized == 0
      echom 'maximizing'
      let g:window_maximized = 1
      :resize | vertical resize
      return
  endif

  if exists('g:window_maximized') && g:window_maximized == 1
      echom 'equalizing windows'
      let g:window_maximized = 0
      :wincmd =
      return
  endif

endfunction

function! CurrentLineA()
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction

function! CurrentLineI()
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = getline('.')[head_pos[2] - 1] !~# '\s'
  return
  \ non_blank_char_exists_p
  \ ? ['v', head_pos, tail_pos]
  \ : 0
endfunction


aug neoterm_setup
  au TermOpen * let g:neoterm_current_id = b:terminal_job_id
  au TermOpen * setlocal nonumber norelativenumber
  au BufUnload term://*
        \ if exists('g:neoterm_current_id') |
        \   unlet g:neoterm_current_id |
        \ endif
aug END

" open an existing buffer
function! OpenExisingTerminal()
  let all_buffers = range(1, bufnr('$'))
  let g:term_buffers = filter(all_buffers, 'bufname(v:val) =~ "term:\/\/.*"')
  exec("botright sb " . g:term_buffers[0])
endfunction

function! ListContains(lst, value)
    for cur_value in a:lst
        if cur_value == a:value
          return 1
        endif
    endfor
    return 0
endfunction

function! ToggleTerminalBuffer()
    let all_buffers = range(1, bufnr('$'))
    let term_buffers = filter(all_buffers, 'bufname(v:val) =~ "term:\/\/.*"')

    if len(term_buffers) == 0
        return 0
    endif

    let term_buf_num = term_buffers[0] 

    if ListContains(tabpagebuflist(), term_buf_num)
        exec("close " . term_buf_num)
    else
        exec("botright sb " . term_buf_num)
    endif
    return 1
endfunction

    

" Color name (:help cterm-colors) or ANSI code
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240

map \c :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>


" if has('nvim') " This way you can also put it in your vim config file
"     call rpcrequest(rpcstart(expand('$HOME/.bin/nvim-hs-devel.sh')), "PingNvimhs")
" endif

set rtp+=/usr/local/opt/fzf

let $NVIM_TUI_ENABLE_TRUE_COLOR=1


" let g:gruvbox_contrast_dark="hard"
nmap <leader>f :call ToggleTerminalBuffer()<cr>
tnoremap <leader>f <c-\><c-n>:call ToggleTerminalBuffer()<cr>

nnoremap <leader>o :call ToggleMaximixed()<cr>

let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
