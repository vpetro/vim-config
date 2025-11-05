local lh = require("vpetro.lsp_helper")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

require'lspconfig'.ts_ls.setup{
  capabilities = capabilities,
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = "/usr/local/lib/node_modules/@vue/typescript-plugin",
        languages = {"javascript", "typescript", "vue"},
      },
    },
  },
  filetypes = {
    "javascript",
    "typescript",
    "vue",
  },
}

lh.setup_keymaps()
lh.setup_diagnostics()
