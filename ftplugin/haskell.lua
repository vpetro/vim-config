local lh = require("vpetro.lsp_helper")
local util = require'lspconfig/util'

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

require'lspconfig'.hls.setup {
    cmd = {"/Users/petrov/.ghcup/bin/haskell-language-server-wrapper", "--lsp"},
    filetypes = {"haskell", "lhaskell"},
    root_dir = util.root_pattern("*.cabal", "stack.yaml", "cabal.project", "package.yaml", "hie.yaml"),
    capabilities = capabilities
}

lh.setup_diagnostics()
lh.setup_keymaps()
