local lh = require("vpetro.lsp_helper")
local workspace_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

local cmd = {
  '/Users/petrov/bin/lsp/java/server',
 '/Users/petrov/code/jdtls/' .. workspace_dir,
}

local config = {
  cmd = cmd,
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),
  capabilities = capabilities,
}

require('jdtls').start_or_attach(config)

lh.setup_diagnostics()
lh.setup_keymaps()
