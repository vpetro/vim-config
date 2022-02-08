local null_ls = require"null-ls"
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup({
    sources = {
        formatting.stylua.with {
          extra_args = { "--indent-type Spaces", "--indent-width 2"}
        },
        formatting.black.with { extra_args = { "--fast" } },
        diagnostics.flake8,
        diagnostics.mypy
    },
})
