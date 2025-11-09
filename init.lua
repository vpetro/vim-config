vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {

  { "tiagovla/tokyodark.nvim", name = "tokyodark",
  config = function()
    require("tokyodark").setup({
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        identifiers = { italic = false },
        functions = {},
        variables = {},
      },
    })
  end,
  },

  { "vpetro/vim-petro-colors", name = "petro" },

  { "tpope/vim-fugitive", name = "fugitive" },

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
    },
    config = function()
      require("telescope").setup({
        extensions = {
          fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
          }
        }
      })

    local telescope = require('telescope.builtin')
    vim.keymap.set('n', '<leader>t', telescope.git_files, {})
    vim.keymap.set('n', '<leader>f', telescope.find_files, {})
    vim.keymap.set('n', '<leader>vh', telescope.help_tags, {})

    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    config = function ()
      require('neo-tree').setup {}
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function ()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {"lua", "python", "rust", "markdown"},
        hightlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  {
    "williamboman/mason.nvim",
    name = "mason",
    config = function ()
      require("mason").setup()
    end
  },

  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "rust_analyzer"}
      })
    end
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "hrsh7th/cmp-buffer",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
      -- "hrsh7th/cmp-path",
      -- "hrsh7th/cmp-cmdline",
    },
    config = function ()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "nvim_lsp_signature_help" },
          { name = "luasnip" },
        }),
        completion = {
          autocomplete = false,
          keyword_length = 3,
        },
        performance = {
          max_view_entries = 10,
        },
      })
    end
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.pyright.setup({
        capabilities = capabilities
      })
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities
      })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})

      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          -- Enable underline, use default values
          underline = false,
          -- Enable virtual text, override spacing to 4
          virtual_text = false,
          -- and on, using buffer local variables
          signs = true,
          -- function(_, bufnr) return vim.b[bufnr].show_signs == true end,
          -- Disable a feature
          update_in_insert = false,
        }
      )
    end

  },

  {
    "folke/trouble.nvim",
    -- dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      icons = false,
      fold_open = "v", -- icon used for open folds
      fold_closed = ">", -- icon used for closed folds
      indent_lines = false, -- add an indent guide below the fold icons
      signs = {
        -- icons / text used for a diagnostic
        error = "E",
        warning = "W",
        hint = "H",
        information = "I"
      },
      use_diagnostic_signs = false,
      mode = "document_diagnostics",
    },
  },

  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function ()
      local null_ls = require('null-ls')
      -- local utils = require("null-ls.utils")
      local diagnostic_config = {
        -- see :help vim.diagnostic.config()
        underline = false,
        virtual_text = false,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
      }
      null_ls.setup {
        sources = {
          -- lua
          null_ls.builtins.formatting.stylua.with({
            diagnostic_config = diagnostic_config,
          }),
          -- python
          null_ls.builtins.formatting.isort.with({
            diagnostic_config = diagnostic_config,
          }),
          null_ls.builtins.formatting.black.with({
            diagnostic_config = diagnostic_config,
          }),
          null_ls.builtins.diagnostics.flake8.with({
            diagnostic_config = diagnostic_config,
          }),
          null_ls.builtins.diagnostics.mypy.with({
            diagnostic_config = diagnostic_config,
          }),

          -- .with({
          -- runtime_condition = function(params)
          --  return utils.path.exists(params.bufname)
          --  end,
          --})
        }
      }
    end,
    opts = {
    }
  },

}

require("lazy").setup(plugins, {})

require("telescope").load_extension("fzy_native")

-- setup lsp key bindings
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    -- vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    -- vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '=f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- quickfix with diagnostics
vim.keymap.set('n', '[q', function()
  vim.diagnostic.setqflist({ open = false })
  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  local action = qf_winid > 0 and 'cclose' or 'copen'
  vim.cmd('botright '..action)
end, {noremap = true, silent = true})

vim.keymap.set('n', ']q', function()
  vim.diagnostic.setqflist({ open = false })
end, {noremap = true, silent = true})

-- move between diagnostic messages
vim.keymap.set('n', '[d',
  function()
    vim.diagnostic.goto_prev()
  end,
  {noremap = true, silent = true}
)

vim.keymap.set('n', ']d',
  function()
    vim.diagnostic.goto_next()
  end,
  {noremap = true, silent = true}
)


vim.cmd [[set expandtab]]
vim.cmd [[set tabstop=2]]
vim.cmd [[set softtabstop=2]]
vim.cmd [[set shiftwidth=2]]
vim.cmd [[ set notermguicolors ]]
vim.cmd [[ colorscheme petro ]]
vim.cmd [[ set signcolumn=yes:1 ]]
