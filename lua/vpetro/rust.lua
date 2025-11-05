local lh = require("vpetro.lsp_helper")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

require'lspconfig'.rust_analyzer.setup{}
-- require'lspconfig'.rust_analyzer.setup{ capabilities = capabilities }
lh.setup_keymaps()
-- lh.setup_diagnostics()
