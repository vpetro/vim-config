local lh = require"vpetro.lsp_helper"
local null_ls = require"null-ls"
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup({
    sources = {
        formatting.stylua.with {
          diagnostic_config = lh.get_diagnostic_config(),
          extra_args = { "--indent-type Spaces", "--indent-width 2"}
        },
        formatting.black.with { diagnostic_config = lh.get_diagnostic_config(), extra_args = { "--fast" } },
        diagnostics.flake8.with { diagnostic_config = lh.get_diagnostic_config() },
        diagnostics.mypy.with { diagnostic_config = lh.get_diagnostic_config() }
    },
})
