local M = {}

local ns = vim.api.nvim_create_namespace("review_notes")

local markers = {
  TODO = true, NOTE = true, FIXME = true, HACK = true, XXX = true,
  BUG = true, TBD = true, WIP = true, NB = true, PS = true,
}

local level_colors = {
  { fg = "#AF8700", ctermfg = 136 },
  { fg = "#6F92B0", ctermfg = 67 },
  { fg = "#7BA05C", ctermfg = 65 },
  { fg = "#9C7497", ctermfg = 96 },
}

local cache = {}

local function level(depth)
  return "ReviewNoteLevel" .. (depth % #level_colors)
end

local function tag_of(s)
  local ws, tag = s:match("^(%s*)(%u+):")
  if tag and #tag <= 8 and not markers[tag] then
    return tag, #ws
  end
end

local function unquote(s)
  local depth, rest = 0, s
  while true do
    local more = rest:match("^%s*>(.*)$")
    if not more then
      break
    end
    depth, rest = depth + 1, more
  end
  return depth, #s - #rest, rest
end

local function code_spans(segs, line, from, to)
  local pos = from + 1
  while true do
    local s, e = line:find("`[^`]+`", pos)
    if not s or s > to then
      break
    end
    segs[#segs + 1] = { s - 1, math.min(e, to), "@markup.raw" }
    pos = e + 1
  end
end

local function scan(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local c = cache[buf]
  if c and c.tick == tick then
    return c
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local rows = {}
  local open, note = false, false
  for i, line in ipairs(lines) do
    local segs = {}
    local from, body_from = nil, 0
    if not open then
      local s = line:find("<!--", 1, true)
      if s then
        open, from = true, s
        segs[#segs + 1] = { s - 1, s + 3, "ReviewNoteDelim" }
        body_from = s + 3
        local tag, ws = tag_of(line:sub(s + 4))
        note = tag ~= nil
        if note then
          local ts = s + 3 + ws
          segs[#segs + 1] = { ts, ts + #tag + 1, level(0) }
          body_from = ts + #tag + 1
        end
      end
    end
    if open then
      local e = line:find("-->", (from or 0) + 1, true)
      local body_to = e and e - 1 or #line
      if not from and note then
        local depth, plen, rest = unquote(line)
        local tag, ws = tag_of(rest)
        local pend = tag and plen + ws + #tag + 1 or plen
        if pend > 0 then
          segs[#segs + 1] = { 0, pend, level(depth) }
        end
        body_from = pend
      end
      if body_to > body_from then
        if note then
          code_spans(segs, line, body_from, body_to)
        else
          segs[#segs + 1] = { body_from, body_to, "ReviewNoteDelim" }
        end
      end
      if e then
        segs[#segs + 1] = { e - 1, e + 2, "ReviewNoteDelim" }
        open, note = false, false
      end
      rows[i] = segs
    end
  end
  c = { tick = tick, rows = rows, any = next(rows) ~= nil }
  cache[buf] = c
  return c
end

local function define_highlights()
  vim.api.nvim_set_hl(0, "ReviewNoteDelim", { link = "Comment" })
  for i, color in ipairs(level_colors) do
    vim.api.nvim_set_hl(0, "ReviewNoteLevel" .. (i - 1), {
      fg = color.fg, ctermfg = color.ctermfg, bold = true, cterm = { bold = true },
    })
  end
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = define_highlights })
  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(ev)
      cache[ev.buf] = nil
    end,
  })
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, _, buf)
      if vim.bo[buf].filetype ~= "markdown" then
        return false
      end
      return scan(buf).any
    end,
    on_line = function(_, _, buf, row)
      local segs = cache[buf].rows[row + 1]
      if not segs then
        return
      end
      for _, seg in ipairs(segs) do
        vim.api.nvim_buf_set_extmark(buf, ns, row, seg[1], {
          end_col = seg[2],
          hl_group = seg[3],
          priority = 110,
          ephemeral = true,
        })
      end
    end,
  })
end

return M
