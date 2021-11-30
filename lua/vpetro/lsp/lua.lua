local configs = require'lspconfig/configs'
local util = require'lspconfig/util'

USER = vim.fn.expand("$USER")

-- local lua_ls_path = "/Users/petrov/oss/lua-language-server"
-- local lua_ls_binary = "/Users/petrov/oss/lua-language-server/bin/macOS/lua-language-server"

local sumneko_root_path = "/Users/petrov/bin/lsp/lua/lua-language-server"
local sumneko_binary = sumneko_root_path .. "/bin/macOS/lua-language-server"


local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)


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

require'lspconfig'.sumneko_lua.setup {
  cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"};
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Setup your lua path
        path = path,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
    },
  },
}

