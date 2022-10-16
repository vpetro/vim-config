local lh = require("vpetro.lsp_helper")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)


require'lspconfig'.metals.setup{
  capabilities = capabilities,
  cmd = { '/Users/petrov/bin/metals-vim' },
  init_options = {
    showImplicitArguments = true,
    showImplicitConversionsAndClasses = true,
    excludePackages = {
      "akka.actor.typed.javadsl",
      "com.github.swagger.akka.javadsl"
    }
  }
}

lh.setup_diagnostics()
lh.setup_keymaps()


-- function to execute various metals commands
local lsp = vim.lsp
local function execute_command(command_params, callback)
  lsp.buf_request(0, "workspace/executeCommand", command_params, function(err, result, ctx)
    if callback then
      callback(err, ctx.method, result)
    end
    -- elseif err then
      --log.error_and_show(string.format("Could not execute command: %s", err.message))
  end)
end

M = {}

function M.import()
  execute_command({ command = "metals.build-import"})
end

return M
