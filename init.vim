 call plug#begin('~/.config/.nvim/plugged')

" themes
Plug 'vpetro/vim-petro-colors'
Plug 'gruvbox-community/gruvbox'

Plug 'L3MON4D3/LuaSnip'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lua', {'branch': 'main'}
Plug 'hrsh7th/cmp-nvim-lsp', {'branch': 'main'}
Plug 'hrsh7th/cmp-buffer', {'branch': 'main'}
Plug 'hrsh7th/cmp-path', {'branch': 'main'}
Plug 'hrsh7th/cmp-cmdline', {'branch': 'main'}
Plug 'hrsh7th/nvim-cmp', {'branch': 'main'}
Plug 'saadparwaiz1/cmp_luasnip'

Plug 'onsails/lspkind.nvim', {'branch': 'master'}

Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }

Plug 'nvim-lua/plenary.nvim'
Plug 'jose-elias-alvarez/null-ls.nvim', {'branch': 'main'}

" java language server
Plug 'mfussenegger/nvim-jdtls'

Plug 'junegunn/goyo.vim'

" Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" Plug 'junegunn/fzf.vim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }


Plug 'tpope/vim-fugitive'

Plug 'tpope/vim-vinegar'

Plug 'terrortylor/nvim-comment', {'branch': 'main'}
call plug#end()

lua require("vpetro")

let g:python3_host_prog = '/Users/petrov/.pyenv/shims/python'
let g:loaded_python_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0


set guifont=Monaco:h13
set background=dark

" set termguicolors
" colorscheme gruvbox
colorscheme petro

" neovim 0.7 global status line. the color scheme has to be tweaked to use this best
" continue to use the same status line as before
" to have a global, set to 3
set laststatus=2

set noerrorbells
set novisualbell
set visualbell t_vb=

set shiftwidth=2
set tabstop=2
set expandtab
set autoindent
set smartindent

set nospell

set list listchars=tab:»·,trail:·,extends:·,precedes:·,

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

set nonumber
set norelativenumber

set ruler

let mapleader = "\<Space>"
let g:mapleader = "\<Space>"

nmap <leader>q :q!<cr>
nmap <leader>w :w!<cr>

ino jj <esc>
cno jj <C-c>


" search improvements
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

" window movement and balancing {
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
" nnoremap <BS>  <C-w>h
nnoremap <C-l> <C-w>l

" Configuration for vim-scala
au BufRead,BufNewFile *.sbt set filetype=scala

autocmd FileType json syntax match Comment +\/\/.\+$+

" set completeopt=menuone,noinsert,noselect
set completeopt=menu,menuone,noselect

set shortmess+=c


map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>


hi! link LspReferenceText CursorColumn
hi! link LspReferenceRead CursorColumn
hi! link LspReferenceWrite CursorColumn


" luasnip configuration
imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 
inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>

snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'

" telescope
nnoremap <C-t> <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

