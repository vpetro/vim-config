local lh = require("vpetro.lsp_helper")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

require'lspconfig'.jedi_language_server.setup{ capabilities = capabilities }

lh.setup_keymaps()
lh.setup_diagnostics()
