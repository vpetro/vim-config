
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


return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = path,
      },
      diagnostics = {
        globals = {'vim', 'hs'},
      },
      workspace = {
        library = {
          -- hammersppon lua location - macos only
          '/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/',
          -- nvim lua files
          vim.api.nvim_get_runtime_file("", true),
          vim.fn.expand("$VIMRUNTIME/lua"),
          "/Users/petrov/.config/nvim",
        },
      },
    },
  },
}

