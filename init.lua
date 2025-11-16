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
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
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

  -- completion & snippets
  -- not sure about the snippets
  -- { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/saghen/blink.cmp' },


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

vim.opt.completeopt = { 'menu', 'menuone', 'noinsert' }
vim.opt.shortmess:append('c')


require('fzf-lua').setup({
  winopts = {
    split = 'botright 20new',
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

vim.keymap.set('n', '<leader>t', '<cmd>FzfLua git_files<cr>')
vim.keymap.set('n', '<leader>f', '<cmd>FzfLua files<cr>')

local function maximize_split()
  vim.cmd('mksession! ~/.session.vim')
  vim.cmd.only()
end

vim.keymap.set('n', '<C-w>u', ':source ~/.session.vim<cr>')
vim.keymap.set('n', '<C-w>o', maximize_split)

vim.keymap.set('n', '<leader>gm', ':Gvdiffsplit main<CR>')
vim.keymap.set('n', '<leader>gh', ':Gclog -- %<CR>')


-- LSP

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  update_in_insert = false,
  underline = true,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(_)
    -- configure signature help
    vim.lsp.handlers['textDocument/signatureHelp'] = {
      border = 'rounded',
      max_width = 80,
      max_height = 10,
      style = 'minimal',
      relative = 'cursor',
      focusable = false,
    }

    -- configure lsp key bindings
    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')

    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
    vim.keymap.set('n', 'gu', '<cmd>lua vim.lsp.buf.references()<CR>')

    vim.keymap.set('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
    vim.keymap.set('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')

    -- enable inline hints for functions and types
    vim.keymap.set('n', '<leader>bb',
      function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end
    )

    -- diagnostics
    vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
    vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
    vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.setloclist()<CR>')
    -- hover a box with the message
    vim.keymap.set('n', '<space>e', '<cmd>lua vim.diagnostic.open_float({scope = "line"})<CR>')
    vim.keymap.set('n', 'gw', '<cmd>lua vim.lsp.buf.format()<CR>')



    vim.keymap.set("n", "gd",
      function()
        vim.cmd("vertical botright split")
        vim.lsp.buf.definition()
        vim.cmd("normal! zz")
      end
    )
  end
})



vim.lsp.enable('lua_ls')
vim.lsp.enable('python')
vim.lsp.enable("ty")
vim.lsp.enable('go')

local null_ls = require('null-ls')
local formatting = null_ls.builtins.formatting

null_ls.setup({
  sources = {
    formatting.stylua.with {
      extra_args = { "--indent-type Spaces", "--indent-width 2" }
    },
    formatting.isort,
  },
})

require("blink.cmp").setup({
  signature = { enabled = true },
  completion = {
    list = {
      selection = { preselect = false, auto_insert = true } },
    menu = {
      auto_show = false,
    },
  },
  keymap = {
    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' },

    ['<Tab>'] = { 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  }
})


require('nvim-treesitter.configs').setup {
  -- "query" is necessary in order to make the query editor work in playground
  ensure_installed = {
    "markdown",
    "query",
    "lua", "vimdoc",
    "python",
    "json", "yaml",
    "javascript", "typescript",
    "go"
  },
  indent = {
    enable = true,
    -- disable = {"python", "yaml"},
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",    -- start selection
      node_incremental = "grn",  -- expand selection
      scope_incremental = "grc", -- expand selection
      node_decremental = "grm"   -- shrink selection
    }
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25,         -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = 'o',
      toggle_hl_groups = 'i',
      toggle_injected_languages = 't',
      toggle_anonymous_nodes = 'a',
      toggle_language_display = 'I',
      focus_language = 'f',
      unfocus_language = 'F',
      update = 'R',
      goto_node = '<cr>',
      show_help = '?',
    },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
    swap = {
      enable = false,
    },
    lsp_interop = {
      enable = true,
      border = 'none',
      floating_preview_opts = {},
      peek_definition_code = {
        ["<leader>df"] = "@function.outer",
        ["<leader>dF"] = "@class.outer",
      },
    },
  },
}
