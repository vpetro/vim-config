

local M = {}

local function execute_command(command, callback)
  vim.lsp.buf_request(0, 'workspace/executeCommand', command, function(err, method, resp)
    if callback then
      callback(err, method, resp)
    elseif err then
      print('Could not execute command: ' .. err.message)
    end
  end)
end

M.build_connect = function()
  execute_command({
    command = 'metals.build-connect';
  })
end

M.build_import = function()
   execute_command({
    command = "metals.build-import";
  })
end

M.build_restart = function()
  execute_command({
    command = 'metals.build-restart';
  })
end

M.doctor_run = function()
  execute_command({
    command = 'metals.doctor-run';
  })
end

return M
