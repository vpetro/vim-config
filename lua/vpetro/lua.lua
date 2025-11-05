local lh = require("vpetro.lsp_helper")
USER = vim.fn.expand("$HOME")

local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local path = vim.split(package.path, ';')
table.insert(path, "lua/?.lua")
table.insert(path, "lua/?/init.lua")
table.insert(path, "/usr/local/Cellar/luarocks/3.8.0/share/lua/5.4/?.lua")
table.insert(path, "/usr/local/share/lua/5.4/?.lua")
table.insert(path, "/usr/local/share/lua/5.4/?/init.lua")
table.insert(path, "/usr/local/lib/lua/5.4/?.lua")
table.insert(path, "/usr/local/lib/lua/5.4/?/init.lua")
table.insert(path, "./?.lua")
table.insert(path, "./?/init.lua")
table.insert(path, "/Users/petrov/.luarocks/share/lua/5.4/?.lua")
table.insert(path, "/Users/petrov/.luarocks/share/lua/5.4/?/init.lua")

require'lspconfig'.lua_ls.setup {
--  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = path,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim', 'hs'},
      },
      workspace = {
        library = {
          -- hammersppon lua location
          '/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/',
          -- nvim lua files
          vim.api.nvim_get_runtime_file("", true),
          vim.fn.expand("$VIMRUNTIME/lua"),
          "/Users/petrov/.config/nvim/lua",
        },
      },
    },
  },
}


lh.setup_diagnostics()
lh.setup_keymaps()
