local null_ls = require("null-ls")
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

local lh = require"vpetro.lsp_helper"

null_ls.setup({
  -- debug = true,
  sources = {
    -- require("none-ls.diagnostics.flake8"),
    require("none-ls.formatting.ruff_format"),

    formatting.stylua.with {
      -- diagnostic_config = lh.diagnostic_config,
      extra_args = { "--indent-type Spaces", "--indent-width 2"}
    },
    -- formatting.black.with {
    --   -- diagnostic_config = lh.diagnostic_config,
    --   extra_args = { "--fast" }
    -- },
    -- formatting.isort.with {},
    -- -- diagnostics.ruff.with {
    -- --   diagnostic_config = lh.diagnostic_config,
    -- --   extra_args = { "--ignore=E501" }
    -- -- },
    -- it is from extras
    -- diagnostics.flake8.with {
    --   diagnostic_config = lh.diagnostic_config,
    --   extra_args = { "--ignore=E501" }
    -- },
    diagnostics.mypy.with {
      -- diagnostic_config = lh.diagnostic_config,
      extra_args = { "--follow-imports", "silent" },
    },
  },
})
