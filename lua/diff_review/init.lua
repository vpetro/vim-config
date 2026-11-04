local notes = require("diff_review.notes")

local api = vim.api
local M = {}

local NULL_BUFFER = "diffview://null"

local marks = api.nvim_create_namespace("diff_review_marks")
local labels = api.nvim_create_namespace("diff_review_labels")

local config = {
  tag = "PV",
  dir = vim.fs.joinpath(vim.fn.stdpath("state"), "diff-review"),
  sign = "◆",
}

local known_disk = {}
local watched = {}
local marked = {}
local prints = {}
local refresh_pending = false

local function notify(msg, level)
  vim.notify("DiffReview: " .. msg, level or vim.log.levels.WARN)
end

local function realpath(p)
  return vim.uv.fs_realpath(p) or p
end

local function disk_lines(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  return vim.fn.readfile(path)
end

local function disk_sha(path)
  local lines = disk_lines(path)
  return lines and notes.fingerprint(lines) or false
end

local function rev_id(rev)
  if type(rev) ~= "table" then
    return nil
  end
  local ok, mod = pcall(require, "diffview.vcs.rev")
  if not ok then
    return nil
  end
  local t = mod.RevType
  if rev.type == t.LOCAL then
    return "LOCAL"
  elseif rev.type == t.STAGE then
    return ":" .. tostring(rev.stage or 0)
  elseif rev.type == t.COMMIT and type(rev.commit) == "string" then
    return rev.commit
  end
  return nil
end

local function view_context()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    return nil, "diffview.nvim is not loaded"
  end
  local view = lib.get_current_view()
  if not view then
    return nil, "no Diffview in this tab"
  end
  local class = view.class and type(view.class.name) == "function" and view.class:name() or "?"
  if class ~= "DiffView" then
    return nil, class .. " is not supported; only :DiffviewOpen comparisons are"
  end
  local layout = view.cur_layout
  if not layout or not tostring(layout.name or ""):match("^diff2_") or not (layout.a and layout.b) then
    return nil, "only two-way diff layouts are supported"
  end
  local entry = view.cur_entry
  if not entry then
    return nil, "no file is open in the view"
  end
  if entry.kind == "conflicting" then
    return nil, "merge conflicts are not supported"
  end
  local toplevel = view.adapter and view.adapter.ctx and view.adapter.ctx.toplevel
  if type(toplevel) ~= "string" then
    return nil, "cannot determine the worktree root"
  end
  local left, right = rev_id(layout.a.file and layout.a.file.rev), rev_id(layout.b.file and layout.b.file.rev)
  if not left or not right then
    return nil, "unsupported revision type in this comparison"
  end
  local ctx = {
    view = view,
    root = realpath(toplevel),
    left = left,
    right = right,
    sides = {},
  }
  for _, sym in ipairs({ "a", "b" }) do
    local win, file = layout[sym], layout[sym].file
    local winid = win.id
    local bufnr = winid and api.nvim_win_is_valid(winid) and api.nvim_win_get_buf(winid) or nil
    local absent = not file or file.nulled or file.binary or not bufnr
      or api.nvim_buf_get_name(bufnr) == NULL_BUFFER
    ctx.sides[sym] = {
      side = sym,
      root = ctx.root,
      left = left,
      right = right,
      path = file and file.path,
      winid = winid,
      bufnr = bufnr,
      absent = absent,
      pending = not absent and bufnr ~= file.bufnr,
    }
  end
  return ctx
end

local function current_side(ctx)
  local winid = api.nvim_get_current_win()
  for _, sym in ipairs({ "a", "b" }) do
    if ctx.sides[sym].winid == winid then
      return ctx.sides[sym]
    end
  end
  return nil
end

local function side_usable(side)
  if side.absent then
    return nil, ("the %s side shows no file content here (absent or binary in that revision)")
      :format(side.side == "a" and "left" or "right")
  end
  if side.pending then
    return nil, "the diff window is still loading; try again"
  end
  return true
end

local function fingerprint(bufnr)
  local tick = api.nvim_buf_get_changedtick(bufnr)
  local c = prints[bufnr]
  if c and c.tick == tick then
    return c.sha
  end
  local sha = notes.fingerprint(api.nvim_buf_get_lines(bufnr, 0, -1, false))
  prints[bufnr] = { tick = tick, sha = sha }
  return sha
end

local function snapshot(side)
  return {
    root = side.root,
    left = side.left,
    right = side.right,
    side = side.side,
    path = side.path,
    sha256 = fingerprint(side.bufnr),
  }
end

local function review_path(root)
  return notes.review_path(realpath(config.dir), root)
end

local function in_review_dir(name)
  if name == "" or not name:match("%.md$") then
    return false
  end
  return realpath(vim.fs.dirname(name)) == realpath(config.dir)
end

local function refresh_later()
  if refresh_pending then
    return
  end
  refresh_pending = true
  vim.schedule(function()
    refresh_pending = false
    M.refresh()
  end)
end

local function follow_changes(bufnr, registry)
  if registry[bufnr] then
    return
  end
  registry[bufnr] = true
  api.nvim_buf_attach(bufnr, false, {
    on_lines = refresh_later,
    on_reload = refresh_later,
    on_detach = function()
      registry[bufnr], prints[bufnr] = nil, nil
    end,
  })
end

local function track(bufnr)
  known_disk[bufnr] = disk_sha(api.nvim_buf_get_name(bufnr))
  follow_changes(bufnr, watched)
  if vim.b[bufnr].diff_review_tracked then
    return
  end
  vim.b[bufnr].diff_review_tracked = true
  api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost" }, {
    buffer = bufnr,
    callback = function()
      known_disk[bufnr] = disk_sha(api.nvim_buf_get_name(bufnr))
      refresh_later()
    end,
  })
  api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    callback = function()
      known_disk[bufnr] = nil
    end,
  })
end

local function reload(bufnr)
  local group = api.nvim_create_augroup("diff_review_reload", { clear = true })
  api.nvim_create_autocmd("FileChangedShell", {
    group = group,
    pattern = "*",
    callback = function(ev)
      if ev.buf == bufnr then
        vim.v.fcs_choice = "reload"
      end
    end,
  })
  vim.cmd(("silent! checktime %d"):format(bufnr))
  api.nvim_del_augroup_by_id(group)
end

local function loaded_review_buffer(path)
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) then
      local name = api.nvim_buf_get_name(bufnr)
      if name == path or (name ~= "" and realpath(name) == path) then
        return bufnr
      end
    end
  end
  return nil
end

local function synced_with_disk(bufnr, path)
  local on_disk = disk_sha(path)
  if not on_disk then
    return true
  end
  local known = known_disk[bufnr]
  if known == nil then
    if vim.bo[bufnr].modified then
      return nil, ("cannot tell whether %s changed on disk since it was read; save (:w) or reload (:e!) it first")
        :format(path)
    end
    known = fingerprint(bufnr)
  end
  if known == on_disk then
    return true
  end
  if vim.bo[bufnr].modified then
    return nil, ("%s changed on disk while its buffer has unsaved edits; save (:w) or reload (:e!) it first")
      :format(path)
  end
  reload(bufnr)
  known_disk[bufnr] = disk_sha(path)
  if vim.bo[bufnr].modified or fingerprint(bufnr) ~= on_disk then
    return nil, ("%s changed on disk and could not be reloaded; reload it (:e!) first"):format(path)
  end
  return true
end

local function review_buffer(root, for_append)
  if for_append then
    vim.fn.mkdir(config.dir, "p")
  end
  local path = review_path(root)
  local bufnr = loaded_review_buffer(path)
  if not bufnr then
    bufnr = vim.fn.bufadd(path)
    vim.fn.bufload(bufnr)
    vim.bo[bufnr].buflisted = true
    if vim.bo[bufnr].filetype == "" then
      vim.bo[bufnr].filetype = "markdown"
    end
    track(bufnr)
  elseif for_append then
    local ok, err = synced_with_disk(bufnr, path)
    if not ok then
      return nil, err
    end
  end
  if for_append and api.nvim_buf_line_count(bufnr) == 1
    and api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "" then
    api.nvim_buf_set_lines(bufnr, 0, 1, false, notes.header_lines(root))
  end
  return bufnr
end

local function append_lines(bufnr, lines)
  local count = api.nvim_buf_line_count(bufnr)
  local last = api.nvim_buf_get_lines(bufnr, count - 1, count, false)[1]
  local block = {}
  if last ~= "" then
    block[1] = ""
  end
  vim.list_extend(block, lines)
  api.nvim_buf_set_lines(bufnr, count, count, false, block)
  return api.nvim_buf_line_count(bufnr)
end

local function show(bufnr)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr then
      api.nvim_set_current_win(win)
      return win
    end
  end
  local win = api.nvim_open_win(bufnr, true, {
    split = "below",
    win = -1,
    height = math.max(10, math.floor(vim.o.lines / 3)),
  })
  for option, value in pairs({
    diff = false,
    scrollbind = false,
    cursorbind = false,
    foldmethod = "manual",
    foldenable = false,
    foldcolumn = "0",
    winhl = "",
    winbar = "",
    wrap = true,
  }) do
    vim.wo[win][option] = value
  end
  return win
end

local function current_notes(root)
  local path = review_path(root)
  local bufnr = loaded_review_buffer(path)
  local lines = bufnr and api.nvim_buf_get_lines(bufnr, 0, -1, false) or disk_lines(path)
  if not lines then
    return {}, {}, nil
  end
  local entries, problems = notes.parse(lines)
  return entries, problems, bufnr
end

local function relevant(entries, side)
  local out = {}
  for _, e in ipairs(entries) do
    local a = e.anchor
    if a.root == side.root and a.left == side.left and a.right == side.right
      and a.side == side.side and a.path == side.path then
      out[#out + 1] = e
    end
  end
  return out
end

local function clear_namespace(registry, ns)
  for bufnr in pairs(registry) do
    if api.nvim_buf_is_loaded(bufnr) then
      api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    else
      registry[bufnr], prints[bufnr] = nil, nil
    end
  end
end

local function clear_marks()
  clear_namespace(marked, marks)
  clear_namespace(watched, labels)
end

local function place_marks(side, entries)
  local bufnr = side.bufnr
  follow_changes(bufnr, marked)
  api.nvim_buf_clear_namespace(bufnr, marks, 0, -1)
  local mine = relevant(entries, side)
  if #mine == 0 then
    return
  end
  local snap = snapshot(side)
  local count = api.nvim_buf_line_count(bufnr)
  for _, e in ipairs(mine) do
    if notes.status(e.anchor, snap) == "current" and e.anchor.lines[2] <= count then
      api.nvim_buf_set_extmark(bufnr, marks, e.anchor.lines[1] - 1, 0, {
        end_row = e.anchor.lines[2] - 1,
        sign_text = config.sign,
        sign_hl_group = "DiffReviewSign",
        priority = 50,
      })
    end
  end
end

local label_text = {
  current = { "current", "DiffReviewCurrent" },
  outdated = { "outdated: the code changed since this note", "DiffReviewOutdated" },
  elsewhere = { "not in the open comparison", "DiffReviewElsewhere" },
}

local function label_review(bufnr, entries, problems, snaps)
  api.nvim_buf_clear_namespace(bufnr, labels, 0, -1)
  local count = api.nvim_buf_line_count(bufnr)
  local function label(line, text, hl)
    if line and line <= count then
      api.nvim_buf_set_extmark(bufnr, labels, line - 1, 0, {
        virt_text = { { " " .. text, hl } },
        virt_text_pos = "eol",
      })
    end
  end
  for _, e in ipairs(entries) do
    local status = "elsewhere"
    for _, snap in ipairs(snaps) do
      local s = notes.status(e.anchor, snap)
      if s == "current" then
        status = s
        break
      elseif s == "outdated" then
        status = s
      end
    end
    label(e.heading or e.line, label_text[status][1], label_text[status][2])
  end
  for _, p in ipairs(problems) do
    label(p.line, "malformed anchor: " .. p.err, "DiffReviewOutdated")
  end
end

function M.refresh()
  local ctx = view_context()
  clear_marks()
  if not ctx then
    return
  end
  local entries, problems, review_bufnr = current_notes(ctx.root)
  local snaps = {}
  for _, sym in ipairs({ "a", "b" }) do
    local side = ctx.sides[sym]
    if side_usable(side) then
      place_marks(side, entries)
      snaps[#snaps + 1] = snapshot(side)
    end
  end
  if review_bufnr then
    label_review(review_bufnr, entries, problems, snaps)
  end
end

function M.comment(line1, line2)
  local ctx, err = view_context()
  if not ctx then
    return notify(err)
  end
  local side = current_side(ctx)
  if not side then
    return notify("move the cursor into one of the two diff windows")
  end
  local ok, why = side_usable(side)
  if not ok then
    return notify(why)
  end
  local lines = api.nvim_buf_get_lines(side.bufnr, 0, -1, false)
  line1, line2 = math.max(1, line1 or 1), math.min(#lines, line2 or line1 or 1)
  if line1 > line2 then
    return notify("the line range is outside the buffer")
  end
  local bufnr, berr = review_buffer(ctx.root, true)
  if not bufnr then
    return notify(berr, vim.log.levels.ERROR)
  end
  local taken = {}
  for _, e in ipairs(notes.parse(api.nvim_buf_get_lines(bufnr, 0, -1, false))) do
    taken[e.anchor.id] = true
  end
  local anchor = {
    root = ctx.root,
    left = ctx.left,
    right = ctx.right,
    side = side.side,
    path = side.path,
    lines = { line1, line2 },
    sha256 = fingerprint(side.bufnr),
    unsaved = vim.bo[side.bufnr].modified or nil,
    created = os.date("%Y-%m-%dT%H:%M:%S%z"),
  }
  anchor.id = notes.new_id(taken, table.concat({
    anchor.root, anchor.path, anchor.side, line1, line2, anchor.sha256, anchor.created, vim.uv.hrtime(),
  }, "\n"))
  local last = append_lines(bufnr, notes.entry_lines({
    anchor = anchor,
    excerpt = vim.list_slice(lines, line1, line2),
    filetype = vim.bo[side.bufnr].filetype,
    tag = config.tag,
  }))
  local win = show(bufnr)
  api.nvim_win_set_cursor(win, { last, #notes.note_prefix(config.tag) })
  M.refresh()
  if api.nvim_get_current_buf() == bufnr then
    vim.cmd("startinsert")
  end
end

local function git_root()
  local name = api.nvim_buf_get_name(0)
  local dir = vim.bo.buftype == "" and name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
  local ok, r = pcall(function()
    return vim.system({ "git", "rev-parse", "--show-toplevel" }, { cwd = dir, text = true }):wait()
  end)
  if not ok or r.code ~= 0 then
    return nil
  end
  return realpath(vim.trim(r.stdout))
end

local function root_for_open()
  local ctx, err = view_context()
  if ctx then
    return ctx
  end
  local root = git_root()
  if root then
    return { root = root }
  end
  return nil, err .. ", and the current directory is not inside a Git worktree"
end

function M.open()
  local ctx, err = root_for_open()
  if not ctx then
    return notify(err)
  end
  local path = review_path(ctx.root)
  if not loaded_review_buffer(path) and vim.fn.filereadable(path) == 0 then
    return notify(("no review notes yet for %s (they would go in %s)"):format(ctx.root, path), vim.log.levels.INFO)
  end
  local target
  if ctx.view then
    local side = current_side(ctx)
    if side and side_usable(side) then
      local lnum = api.nvim_win_get_cursor(0)[1]
      local snap = snapshot(side)
      local entries = current_notes(ctx.root)
      for _, e in ipairs(entries) do
        local a = e.anchor
        if notes.status(a, snap) == "current" and a.lines[1] <= lnum and lnum <= a.lines[2] then
          target = e
          break
        end
      end
    end
  end
  local bufnr, berr = review_buffer(ctx.root, false)
  if not bufnr then
    return notify(berr, vim.log.levels.ERROR)
  end
  local win = show(bufnr)
  if target then
    api.nvim_win_set_cursor(win, { target.thread or target.line, 0 })
  end
  M.refresh()
end

function M.path()
  local ctx, err = root_for_open()
  if not ctx then
    return nil, err
  end
  return review_path(ctx.root)
end

function M.keymaps()
  return {
    { "n", "<leader>nc", "<cmd>DiffReviewComment<CR>", { desc = "Review note on this line" } },
    { "x", "<leader>nc", ":DiffReviewComment<CR>", { desc = "Review note on the selected lines" } },
    { "n", "<leader>no", "<cmd>DiffReviewOpen<CR>", { desc = "Open the review notes" } },
  }
end

local function highlights()
  vim.api.nvim_set_hl(0, "DiffReviewSign", { default = true, fg = "#AF8700", ctermfg = 136, bold = true })
  vim.api.nvim_set_hl(0, "DiffReviewCurrent", { default = true, link = "DiagnosticOk" })
  vim.api.nvim_set_hl(0, "DiffReviewOutdated", { default = true, link = "DiagnosticWarn" })
  vim.api.nvim_set_hl(0, "DiffReviewElsewhere", { default = true, link = "Comment" })
end

function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})
  config.dir = vim.fs.normalize(config.dir)
  highlights()

  local group = api.nvim_create_augroup("diff_review", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "DiffviewDiffBufWinEnter", "DiffviewViewEnter" },
    callback = refresh_later,
  })
  api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "DiffviewViewLeave", "DiffviewViewClosed" },
    callback = clear_marks,
  })
  api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    callback = function(ev)
      if in_review_dir(api.nvim_buf_get_name(ev.buf)) then
        track(ev.buf)
        refresh_later()
      end
    end,
  })

  api.nvim_create_user_command("DiffReviewComment", function(cmd)
    M.comment(cmd.line1, cmd.line2)
  end, { range = true, desc = "Add a review note for the current line or range in a Diffview" })
  api.nvim_create_user_command("DiffReviewOpen", M.open, { desc = "Open the review notes for this worktree" })
  api.nvim_create_user_command("DiffReviewPath", function()
    local path, err = M.path()
    if path then
      print(path)
    else
      notify(err)
    end
  end, { desc = "Print the review notes file path for this worktree" })
end

return M
