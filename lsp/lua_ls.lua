local home = vim.env.HOME
local sysname = vim.uv.os_uname().sysname

local path = vim.split(package.path, ';')

table.insert(path, "lua/?.lua")
table.insert(path, "lua/?/init.lua")
table.insert(path, "./?.lua")
table.insert(path, "./?/init.lua")
table.insert(path, home .. "/.luarocks/share/lua/5.4/?.lua")
table.insert(path, home .. "/.luarocks/share/lua/5.4/?/init.lua")

-- common system prefixes; lua_ls ignores ones that don't exist
table.insert(path, "/usr/local/share/lua/5.4/?.lua")
table.insert(path, "/usr/local/share/lua/5.4/?/init.lua")
table.insert(path, "/usr/local/lib/lua/5.4/?.lua")
table.insert(path, "/usr/local/lib/lua/5.4/?/init.lua")
table.insert(path, "/usr/share/lua/5.4/?.lua")
table.insert(path, "/usr/share/lua/5.4/?/init.lua")

-- whatever luarocks itself reports — covers homebrew on intel/apple
-- silicon and distro packages without hardcoding prefix or version
local ok, out = pcall(vim.fn.system, { "luarocks", "--lua-version=5.4", "path", "--lr-path" })
if ok and vim.v.shell_error == 0 then
  for _, p in ipairs(vim.split(vim.trim(out), ";", { plain = true, trimempty = true })) do
    table.insert(path, p)
  end
end

local library = {
  vim.api.nvim_get_runtime_file("", true),
  vim.fn.expand("$VIMRUNTIME/lua"),
  home .. "/.config/nvim",
}

if sysname == "Darwin" then
  local hs = "/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/"
  if vim.fn.isdirectory(hs) == 1 then
    table.insert(library, hs)
  end
end

return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc' },
  settings = {
    Lua = {
      hint = {
        enable = true,
      },
      runtime = {
        version = 'LuaJIT',
        path = path,
      },
      diagnostics = {
        globals = { 'vim', 'hs' },
      },
      workspace = {
        library = library,
      },
    },
  },
}
