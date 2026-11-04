local M = {}

M.version = 1

local markers = {
  TODO = true, NOTE = true, FIXME = true, HACK = true, XXX = true,
  BUG = true, TBD = true, WIP = true, NB = true, PS = true,
}

local fields = { "id", "root", "left", "right", "side", "path", "lines", "sha256", "unsaved", "created" }

local function backtick_runs(s, min)
  local n = min
  for run in s:gmatch("`+") do
    n = math.max(n, #run + 1)
  end
  return n
end

function M.fingerprint(lines)
  return vim.fn.sha256(table.concat(lines, "\n"))
end

function M.review_path(dir, root)
  local base = (root:match("([^/]+)/*$") or "root"):gsub("[^%w._-]", "_")
  return dir .. "/" .. base .. "-" .. vim.fn.sha256(root):sub(1, 12) .. ".md"
end

function M.new_id(taken, seed)
  local id = vim.fn.sha256(seed):sub(1, 8)
  while taken[id] do
    id = vim.fn.sha256(id .. seed):sub(1, 8)
  end
  return id
end

function M.describe_rev(rev)
  if rev == "LOCAL" then
    return "working tree"
  end
  local stage = rev:match("^:(%d+)$")
  if stage == "0" then
    return "index"
  elseif stage then
    return "index stage " .. stage
  end
  if rev:match("^%x+$") and #rev >= 10 then
    return rev:sub(1, 10)
  end
  return rev
end

function M.code_span(s)
  local d = string.rep("`", backtick_runs(s, 1))
  if s:match("^`") or s:match("`$") then
    s = " " .. s .. " "
  end
  return d .. s .. d
end

function M.fence(excerpt)
  local n = 3
  for _, line in ipairs(excerpt) do
    n = backtick_runs(line, n)
  end
  return string.rep("`", n)
end

function M.encode_anchor(anchor)
  local parts = {}
  for _, key in ipairs(fields) do
    local value = anchor[key]
    if value ~= nil then
      parts[#parts + 1] = vim.json.encode(key) .. ":" .. vim.json.encode(value)
    end
  end
  local json = table.concat(parts, ","):gsub("<", "\\u003c"):gsub(">", "\\u003e")
  return ("<!-- diff-review v%d {%s} -->"):format(M.version, json)
end

function M.is_anchor_line(line)
  return line:match("^%s*<!%-%-%s*diff%-review%f[%W]") ~= nil
end

local function validate(a)
  if type(a) ~= "table" or vim.islist(a) then
    return "anchor is not a JSON object"
  end
  for _, key in ipairs({ "id", "root", "left", "right", "path" }) do
    if type(a[key]) ~= "string" or a[key] == "" then
      return ("anchor field %q must be a non-empty string"):format(key)
    end
  end
  if a.side ~= "a" and a.side ~= "b" then
    return 'anchor field "side" must be "a" or "b"'
  end
  local l = a.lines
  if type(l) ~= "table" or #l ~= 2 or type(l[1]) ~= "number" or type(l[2]) ~= "number"
    or l[1] % 1 ~= 0 or l[2] % 1 ~= 0 or l[1] < 1 or l[2] < l[1] then
    return 'anchor field "lines" must be [first, last] with 1 <= first <= last'
  end
  if type(a.sha256) ~= "string" or not a.sha256:match("^%x+$") or #a.sha256 ~= 64 then
    return 'anchor field "sha256" must be a 64-character hex digest'
  end
  if a.unsaved ~= nil and type(a.unsaved) ~= "boolean" then
    return 'anchor field "unsaved" must be a boolean'
  end
  if a.created ~= nil and type(a.created) ~= "string" then
    return 'anchor field "created" must be a string'
  end
  return nil
end

function M.decode_anchor(line)
  local version, body = line:match("^%s*<!%-%-%s*diff%-review v(%d+)%s+(.*)%-%->%s*$")
  if not version then
    return nil, "anchor comment is not in the form <!-- diff-review v1 {...} -->"
  end
  if tonumber(version) ~= M.version then
    return nil, ("unsupported anchor version v%s"):format(version)
  end
  local ok, data = pcall(vim.json.decode, body)
  if not ok then
    return nil, "anchor JSON does not parse"
  end
  local err = validate(data)
  if err then
    return nil, err
  end
  return data
end

function M.thread_tag(line)
  local tag = line:match("^%s*<!%-%-%s*(%u+):")
  if tag and #tag <= 8 and not markers[tag] then
    return tag
  end
  return nil
end

function M.parse(lines)
  local entries, problems = {}, {}
  local heading, cur
  for i, line in ipairs(lines) do
    if line:match("^##%s") then
      heading, cur = i, nil
    elseif M.is_anchor_line(line) then
      local anchor, err = M.decode_anchor(line)
      if anchor then
        cur = { anchor = anchor, line = i, heading = heading }
        entries[#entries + 1] = cur
      else
        problems[#problems + 1] = { line = i, err = err }
        cur = nil
      end
      heading = nil
    elseif cur and not cur.thread and M.thread_tag(line) then
      cur.thread = i
    end
  end
  return entries, problems
end

function M.header_lines(root)
  return {
    "# Diff review notes: " .. M.code_span(root),
    "",
    "Notes taken in Neovim's Diffview for this worktree. Each `## ` entry has",
    "an anchor comment that locates the code, the selected lines, and a review",
    "thread. Reply inside the thread comment, one `>` per level of depth, and",
    "leave the anchor comments as they are.",
  }
end

function M.side_label(anchor)
  local rev = anchor.side == "a" and anchor.left or anchor.right
  local label = ("%s: %s"):format(anchor.side == "a" and "left" or "right", M.describe_rev(rev))
  if anchor.unsaved then
    label = label .. ", unsaved buffer"
  end
  return label
end

function M.entry_lines(opts)
  local a = opts.anchor
  local range = a.lines[1] == a.lines[2] and ("line %d"):format(a.lines[1])
    or ("lines %d-%d"):format(a.lines[1], a.lines[2])
  local fence = M.fence(opts.excerpt)
  local info = opts.filetype and opts.filetype:match("^[%w_.+-]+$") or ""
  local out = {
    ("## %s %s (%s)"):format(M.code_span(a.path), range, M.side_label(a)),
    "",
    M.encode_anchor(a),
    "",
    fence .. info,
  }
  vim.list_extend(out, opts.excerpt)
  out[#out + 1] = fence
  out[#out + 1] = ""
  out[#out + 1] = M.note_prefix(opts.tag) .. " -->"
  return out
end

function M.note_prefix(tag)
  return ("<!-- %s: "):format(tag)
end

function M.status(anchor, snap)
  if anchor.root ~= snap.root or anchor.left ~= snap.left or anchor.right ~= snap.right
    or anchor.side ~= snap.side or anchor.path ~= snap.path then
    return "elsewhere"
  end
  return anchor.sha256 == snap.sha256 and "current" or "outdated"
end

return M
