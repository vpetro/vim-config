local lh = require("vpetro.lsp_helper")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- require'lspconfig'.pyright.setup {
--   capabilities = capabilities,
--   settings = {
--     pyright = { 
--       autoImportCompletion = true, 
--     },
--     python = {
--       analysis = {
--         autoSearchPaths = true,
--         diagnosticMode = 'openFilesOnly',
--         useLibraryCodeForTypes = true,
--         typeCheckingMode = 'off'
--       }
--     }
--   }
-- }

require'lspconfig'.basedpyright.setup {
  capabilities = capabilities,
  settings = {
    -- basedpyright = {
    --   autoImportCompletion = true,
    --   disableOrganizeImports = true,
    --   diagnosticMode = "openFilesOnly",
    -- },
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
        typeCheckingMode = 'off',
        autoImportCompletions = true,
      }
    }
  }
}

-- require'lspconfig'.ruff.setup {
--   cmd = {"ruff", "server", "--preview"},
--   init_options = {
--     settings = {
--       showSyntaxErrors = true,
--       lint = {
--         enable = true,
--         select = {"E", "F", "W", "I", "ERA"},
--         ignore = {"E501"}
--       }
--     }
--   }
-- }


lh.setup_keymaps()
lh.setup_diagnostics()
