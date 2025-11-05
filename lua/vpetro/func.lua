
function _get_selection()
    local start_pos = vim.fn.getpos('v')
    local end_pos = vim.fn.getpos('.')

    -- Get the line and column numbers
    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- Adjust end column for visual line mode
    if vim.fn.mode() == 'V' then
        end_col = -1  -- Select entire lines
    end

    -- Get the selected lines
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    -- For visual block mode, slice each line
    if vim.fn.mode() == '\22' then  -- \22 is visual block mode
        for i, line in ipairs(lines) do
            lines[i] = line:sub(start_col, end_col)
        end
    else
        -- For character and line visual modes
        if #lines == 1 then
            lines[1] = lines[1]:sub(start_col, end_col)
        else
            -- First line
            print(vim.inspect(lines))
            lines[1] = lines[1]:sub(start_col)
            -- Last line
            lines[#lines] = lines[#lines]:sub(1, end_col)
        end
    end

    return lines
end

-- local function _format_string()
--   local s = "hello\nthere\n```python\nprint()\n```"
--   local lines = vim.split(s, '\n')

--   local spaced_lines = {}
--   local have_match = false

--   for _, line in pairs(lines) do
--     if string.match(line, "^```") ~= nil then
--       if have_match then
--         table.insert(spaced_lines, line)
--         table.insert(spaced_lines, "")
--         have_match = false
--       else
--         table.insert(spaced_lines, line)
--         have_match = true
--       end
--     else
--       table.insert(spaced_lines, line)
--     end
--   end

--   local current_buf = vim.api.nvim_get_current_buf()
--   local current_line = vim.api.nvim_win_get_cursor(0)[1]

--   vim.api.nvim_buf_set_lines(
--       current_buf,
--       current_line,
--       current_line,
--       false,
--       spaced_lines
--   )
-- end

-- vim.keymap.set('n', '<C-e>', _format_string, {})


-- local function _format_string2(lines)

--   local current_buf = vim.api.nvim_get_current_buf()
--   local current_line = vim.api.nvim_win_get_cursor(0)[1]


--   local have_match = false
--   local spaced_lines = {}

--   for _, line in pairs(lines) do
--     if string.match(line, "^```") ~= nil then
--       if have_match then
--         table.insert(spaced_lines, "")
--         table.insert(spaced_lines, line)
--         have_match = false
--       else
--         table.insert(spaced_lines, line)
--         table.insert(spaced_lines, "")
--         have_match = true
--       end
--     else
--       table.insert(spaced_lines, line)
--     end
--   end
--   vim.api.nvim_buf_set_lines(
--       current_buf,
--       current_line,
--       current_line,
--       false,
--       spaced_lines
--   )
-- end

-- _format_string2()

-- local ts_utils = require('nvim-treesitter.ts_utils')

function _select_inside_markdown_block()

  -- vim.treesitter.query.set("markdown", "fenced_block_content", [[
  --   (fenced_code_block
  --     (code_fence_content) @block_content)
  -- ]]
  -- )

  -- local parser = vim.treesitter.get_parser(0, "markdown")
  -- local tree = parser:parse()[1]
  -- local root = tree:root()

  -- local current_buf = vim.api.nvim_get_current_buf()
  -- zero is the curent window where
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- get the node at the current cursor position
  local node = vim.treesitter.get_node({pos = { row -1, col }})

  -- vim.notify("getting the current node")

  -- we are somehow not on a treesitter node
  if not node then return end

  -- vim.notify("got the current node")

  -- walk up the tree until we find the fenced block content node
  while node and node:type() ~= "code_fence_content" do
    node = node:parent()
  end

  if not node then return end

  local start_row, start_col, end_row, _  = node:range()

  vim.notify("got the node")

  vim.notify(vim.inspect({start_row, end_row}))
  select_lines(start_row, start_col, end_row - 1, 0)
end

function select_lines(start_line, start_col, end_line, end_col)
  -- if we're not in visual mode, start it
  if not vim.fn.mode():match('[vV]') then
    vim.cmd("normal! v")
  end

  -- move to the first line of the block
  vim.api.nvim_win_set_cursor(0, {start_line+1, 0})

  -- go back to where we started the visual selection
  vim.cmd('normal! o')

  -- move to the end of the block
  vim.api.nvim_win_set_cursor(0, { end_line + 1, 0 })

  -- move the cursor to the end of the last line of the block
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, { end_line + 1, #line })
end


vim.keymap.set(
  'x', -- mode
  'if', -- mapping
  _select_inside_markdown_block
)

vim.keymap.set(
  'v', -- mode
  '<c-d>', -- mapping
  function() vim.api.nvim_feedkeys("<Esc>", "n", false) end
)

local llm = require('llm')
llm.load()
local http = require('http')
