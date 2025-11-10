
vim.pack.add({
  {
    src = 'http://github.com/vpetro/vim-petro-colors',
    name = 'petro-colors'
  },
  { src = 'https://github.com/catppuccin/nvim' },

  -- treesitter
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/nvim-treesitter/playground' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },

  -- generic lsp
  { src = 'https://github.com/nvimtools/none-ls.nvim' },
  { src = 'https://github.com/nvimtools/none-ls-extras.nvim' },

  -- git
  { src = 'https://github.com/tpope/vim-fugitive' },

  -- better netrw
  { src = 'https://github.com/tpope/vim-vinegar' },

  -- comments
  { src = 'https://github.com/tpope/vim-commentary' },

  -- surrounding text objects
  { src = 'https://github.com/tpope/vim-surround' },

  -- rainbow parens
  { src = 'https://github.com/HiPhish/rainbow-delimiters.nvim' },

  -- distraction free mode
  { src = 'https://github.com/junegunn/goyo.vim' },

  -- fuzzy finder
  { src = 'https://github.com/ibhagwan/fzf-lua' },
})


vim.opt.encoding = "utf-8"
vim.opt.swapfile = false
vim.opt.background = "dark"
vim.opt.termguicolors = false

vim.opt.laststatus = 2

-- disable visual the beep and the visual bell/flash
vim.opt.belloff = 'all'

vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.spell = false

vim.opt.list = true
vim.opt.listchars = {
  -- space = '·',
  tab = '» ',
  extends = '»',
  precedes = '«',
  -- eol = '↲',
}

vim.opt.suffixes = {
  '.bak',
  '.',
  '.swp',
  '.o',
  '.info',
  '.aux',
  '.log',
  '.dvi',
  '.bbl',
  '.blg',
  '.brf',
  '.cb',
  '.ind',
  '.idx',
  '.ilg',
  '.inx',
  '.out',
  '.toc',
  '.cmi',
  '.cmo',
  '.cmx',
  '.cmxa',
  '.exe',
  '.ho',
  '.hi',
  '.bc',
  '.out',
  '.annot',
  '.spot'
}

vim.opt.wildmenu = true

vim.opt.wildignore = { 
  '*/.hg/*',
  '*/.svn/*',
  '*/images/*',
  '*/target/*',
  '*/.idea/*',
  '*.dll',
  '*.exe',
  '*.o',
  '*.obj',
  '*.class',
  '*.pyc',
  '*.pidb',
  '*.jar',
  '*.class',
  '*.aux',
  '*.bbl',
  '*.blg',
  '*.fdb_latexmk',
  '*.bst',
  '*.pdf',
  '*.png',
  '*.jpg',
  '*.gif',
  '*.bson',
  '*.snb'
}

vim.opt.number = false
vim.opt.relativenumber = false

vim.opt.ruler = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

vim.opt.wrap = false

vim.opt.signcolumn = 'yes'

vim.opt.completeopt = {'menu', 'menuone', 'noinsert' }
vim.opt.shortmess:append('c')


require('fzf-lua').setup({
  winopts = {
    split = 'belowright 20new',
    border = 'single',
    preview = {
      hidden = 'hidden',
      border = 'border',
      title = false,
      layout = 'horizontal',
      horizontal = 'right:50%',
    },
  },
})

require('catppuccin').setup({
  background = { dark = 'macchiato' }
})

vim.cmd.colorscheme("petro")


vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>q', ':q!<cr>')
vim.keymap.set('n', '<leader>w', ':w!<cr>')

vim.keymap.set('n', '<C-n>', ':nohl<CR>')
vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')
vim.keymap.set('n', 'g*', 'g*zz')
vim.keymap.set('n', 'g#', 'g#zz')

vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

vim.keymap.set('n', '<leader>t', ':GitFiles<cr>')
vim.keymap.set('n', '<leader>f', ':Files<cr>')
vim.keymap.set('n', '<leader>b', ':Buffers<cr>')

local function maximize_split()
  vim.cmd('mksession! ~/.session.vim')
  vim.cmd.only()
end

vim.keymap.set('n', '<C-w>u', ':source ~/.session.vim<cr>')
vim.keymap.set('n', '<C-w>o', maximize_split)

vim.keymap.set('n', '<leader>gm', ':Gvdiffsplit main<CR>')
vim.keymap.set('n', '<leader>gh', ':Gclog -- %<CR>')


vim.lsp.enable('lua_ls')
