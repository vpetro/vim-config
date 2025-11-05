 call plug#begin('~/.config/.nvim/plugged')

" themes

Plug 'vpetro/vim-petro-colors'
Plug 'EdenEast/nightfox.nvim', {'branch': 'main'}
Plug 'catppuccin/nvim', {'branch': 'main', 'as': 'catppuccin' }

Plug 'lukas-reineke/indent-blankline.nvim', {'branch': 'master'}
Plug 'HiPhish/rainbow-delimiters.nvim', {'branch': 'master'}


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
Plug 'nvim-treesitter/playground'
Plug 'nvim-treesitter/nvim-treesitter-textobjects'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvimtools/none-ls.nvim', {'branch': 'main'}
Plug 'nvimtools/none-ls-extras.nvim', {'branch': 'main'}


Plug 'junegunn/goyo.vim'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-tree/nvim-tree.lua'

Plug 'tpope/vim-fugitive'


Plug 'tpope/vim-vinegar'

Plug 'tpope/vim-commentary'

Plug 'tpope/vim-surround'

Plug 'cuducos/yaml.nvim', {'branch': 'main'}
Plug 'samueljoli/hurl.nvim', {'branch': 'main'}
Plug 'NoahTheDuke/vim-just', {'branch': 'main'}
Plug 'ekalinin/dockerfile.vim'


set encoding=utf-8

call plug#end()

lua require("vpetro")
lua require("yaml_nvim")

let g:python3_host_prog = '/Users/petrov/.pyenv/shims/python'
let g:loaded_python_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0

set noswapfile


set guifont=Monaco:h13
set background=dark

set notermguicolors
colorscheme petro

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

" turn off line wrapping
set nowrap

" turn off the sign column by default, can tun it on later
set signcolumn=no

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
" set completeopt=menu,menuone,noselect
set completeopt=menu,menuone

set shortmess+=c

" setup folding by using treesitter
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set foldenable
set foldlevel=0
set foldnestmax=1

" set foldclose=all " Close folds if you leave them in any way
" set foldcolumn=1 " Show the foldcolumn
" set foldmethod=syntax " Fold on the syntax
" set foldopen=all " Open folds if you touch them in any way

hi! link LspReferenceText CursorColumn
hi! link LspReferenceRead CursorColumn
hi! link LspReferenceWrite CursorColumn

set signcolumn=yes

" luasnip configuration
imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 
inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>

snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'

" telescope
" nnoremap <leader>t <cmd>lua require('telescope.builtin').find_files()<cr>
" nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
" fzf
nnoremap <leader>t :GitFiles<cr>
nnoremap <leader>f :Files<cr>
nnoremap <leader>b :Buffers<cr>

nnoremap <C-w>u :source ~/session.vim<CR>
nnoremap <C-w>o :mksession! ~/session.vim<CR>:wincmd o<CR>

nmap <space>gm :Gvdiffsplit main<cr>
nmap <space>gh :Gclog -- %<cr>
