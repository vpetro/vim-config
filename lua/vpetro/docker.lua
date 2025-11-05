local lh = require("vpetro.lsp_helper")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

require'lspconfig'.dockerls.setup {
  settings = {
    docker = {
      languageserver = {
        formatter = {
          ignoreMultilineInstructions = true,
        },
      },
    }
  }
}

require'lspconfig'.docker_compose_language_service.setup{}
