
M = {}


M.diagnostic_config = { virtual_text = false, signs = true, update_in_insert = false, underline = true }

function M.setup_diagnostics()
  vim.diagnostic.config(M.diagnostic_config)
  -- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  --     vim.lsp.diagnostic.on_publish_diagnostics, M.diagnostic_config
  --    -- { virtual_text = false, }
  --   )
end


function M.setup_keymaps()
  local opts = { noremap=true, silent=true }



  vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    {
      border = 'rounded',
      max_width = 80,
      max_height = 10,
      style = 'minimal',
      relative = 'cursor',
      focusable = false,
    }
  )

  vim.api.nvim_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_set_keymap('n', 'vd', ':vertical botright split | lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)

  -- vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_set_keymap(
    'i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', {})

  vim.api.nvim_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_set_keymap('n', 'gu', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

  -- diagnostics
  vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  vim.api.nvim_set_keymap('n', 'gl', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  -- hover a box with the message
  vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float({scope = "line"})<CR>', opts)
  vim.api.nvim_set_keymap('n', 'gw', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
end


-- vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
vim.keymap.set("n", "gd", function()
  vim.cmd("vertical botright split")
  vim.lsp.buf.definition()
  vim.cmd("normal! zz")
end, { noremap=true, silent=true, desc="Go to definition in a new split and center" }
)


return M
