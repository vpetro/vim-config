-- Try to find luarocks executable
-- local luarocks_exec = vim.fn.executable('luarocks')

-- if luarocks_exec == 1 then
--   -- Get LuaRocks path
--   local luarocks_path = vim.fn.system('luarocks --lua-version=5.1 path'):gsub('\n', '')

--   -- Split and add paths
--   for path in luarocks_path:gmatch('[^;]+') do
--     if path:match('/?.lua$') then
--       package.path = package.path .. ';' .. path
--     elseif path:match('/?.so$') then
--       package.cpath = package.cpath .. ';' .. path
--     end
--   end
-- else
--   vim.notify('LuaRocks not found', vim.log.levels.WARN)
-- end

-- package.path = package.path .. ";" .. "/Users/petrov/.luarocks"
-- package.path = package.path .. ";" .. "/Users/petrov/.luarocks/share/lua/5.1"
--

local home = os.getenv("HOME")

if home == nil then
    return
end

local path = table.concat({
    '/usr/share/lua/5.1/?.lua',
    '/usr/share/lua/5.1/?/init.lua',
    '/usr/lib/lua/5.1/?.lua',
    '/usr/lib/lua/5.1/?/init.lua',
    './?.lua',
    './?/init.lua',
    '~/.luarocks/share/lua/5.1/?.lua',
    '~/.luarocks/share/lua/5.1/?/init.lua'
}, ";")

local cpath = table.concat({
    '/usr/lib/lua/5.1/?.so',
    '/usr/lib/lua/5.1/loadall.so',
    './?.so',
    '~/.luarocks/lib/lua/5.1/?.so'
}, ";")

package.path = path:gsub("~", home)
package.cpath = cpath:gsub("~", home)


require'vpetro.lsp_helper'

-- lsp
require'vpetro.lua'
-- require'vpetro.scala'
-- require'vpetro.js'
require'vpetro.rust'
require'vpetro.docker'

require'vpetro.python'
require'vpetro.null'


-- require'vpetro.dart'

-- require'vpetro.snippets'
require'vpetro.completion'
require'vpetro.treesitter'

-- llm plugin
-- require("vpetro.llm").setup()
-- require("vpetro.llm_streamng").setup({})
-- require("vpetro.llm_streaming")


vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
  renderer = {
    icons = {
      show = {
        file = false,
        folder_arrow = false,
        folder = false,
        git = false,
        diagnostics = false,
        modified = false,
      }
    },
  },
})
local nvim_tree_api = require("nvim-tree.api")
vim.keymap.set('n', '<Space>nt', nvim_tree_api.tree.toggle)

require("catppuccin").setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
  term_colors = true,
  transparent_background = false,
  no_italic = false,
  no_bold = false,
  styles = {
    comments = {},
    conditionals = {},
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
  },
  color_overrides = {
    mocha = {
      base = "#000000",
      mantle = "#000000",
      crust = "#000000",
    },
  },
  highlight_overrides = {
    mocha = function(C)
      return {
        TabLineSel = { bg = C.pink },
        CmpBorder = { fg = C.surface2 },
        Pmenu = { bg = C.none },
        TelescopeBorder = { link = "FloatBorder" },
      }
    end,
  },
})


local capabilities = vim.lsp.protocol.make_client_capabilities()

require("lspconfig")["yamlls"].setup({
    {
    -- on_attach = def.on_attach,
    capabilities = capabilities,
    filetypes = { "yaml", "yml" },
    flags = { debounce_test_changes = 150 },
    settings = {
      yaml = {
        format = {
          enable = true,
          singleQuote = true,
          printWidth = 120,
        },
        hover = true,
        completion = true,
        validate = true,
      },
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["http://json.schemastore.org/github-action"] = { ".github/action.{yml,yaml}" },
      },
      schemaStore = {
        enable = true,
        url = "https://www.schemastore.org/api/json/catalog.json",
      },
    },
  },
})

-- require("lspconfig")["gopls"].setup({
--   capabilities = capabilities,
--   cmd = {"gopls"},
--   filetypes = { "go", "gomod", "gowork", "gotmpl" },
--   -- root_dir = util.root_pattern("go.work", "go.mod", ".git"),
--   settings = {
--     gopls = {
--       completeUnimported = true,
--       usePlaceholders = true,
--       analyses = {
--         unusedparams = true,
--       },
--     },
--   },
-- })

require("lspconfig")["gopls"].setup({
  cmd = { 'gopls' },
  capabilities = capabilities,
  -- for postfix snippets and analyzers
  settings = {
    gopls = {
      buildFlags = { "-tags=wireinject" },
      experimentalPostfixCompletions = true,
      analyses = {
        unusedparams = true,
        shadow = true,
        nilness = true,
        unusedwrite = true,
        useany = true,
      },
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      staticcheck = true,
      semanticTokens = true,
      ["ui.inlayhint.hints"] = {
        compositeLiteralFields = true,
        constantValues = true,
        parameterNames = true,
        functionTypeParameters = true,
        compositeLiteralTypes = true,
        assignVariableTypes = true,
      },
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
      usePlaceholders = true,
    },
  },
  -- on_attach = function(cl, bfrn)
  --   local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
  --   vim.api.nvim_create_autocmd("BufWritePre", {
  --     pattern = "*.go",
  --     callback = function()
  --       require('go.format').goimports()
  --     end,
  --     group = format_sync_grp,
  --   })
  --   on_attach(cl, bfrn)
  -- end,
})
