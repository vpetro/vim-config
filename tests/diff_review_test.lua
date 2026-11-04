local api = vim.api
local uv = vim.uv

local script = vim.fn.fnamemodify(arg[0], ":p")
local config_root = vim.fn.fnamemodify(script, ":h:h")
local diffview_path = os.getenv("DIFFVIEW_PATH")
  or vim.fn.expand("~/.local/share/nvim/site/pack/core/opt/diffview.nvim")

vim.opt.runtimepath:prepend(config_root)
vim.opt.runtimepath:append(diffview_path)
vim.cmd("filetype on")
vim.cmd("runtime! plugin/diffview.lua")
vim.g.mapleader = " "
vim.o.signcolumn = "yes"

local dr = require("diff_review")
local notes = require("diff_review.notes")

local sandbox = arg[2] or (vim.fn.tempname() .. "-diff-review")
vim.fn.mkdir(sandbox .. "/state", "p")
local state_dir = uv.fs_realpath(sandbox .. "/state")

dr.setup({ dir = state_dir, tag = "PV" })
require("diffview").setup({ keymaps = { view = dr.keymaps() } })

local messages = {}
vim.notify = function(msg)
  messages[#messages + 1] = msg
end

local function last_message()
  return messages[#messages] or ""
end

local function sh(args, cwd)
  local r = vim.system(args, { cwd = cwd, text = true }):wait()
  assert(r.code == 0, table.concat(args, " ") .. " failed:\n" .. (r.stderr or ""))
  return vim.trim(r.stdout or "")
end

local function write(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  assert(vim.fn.writefile(lines, path) == 0, "writefile " .. path)
end

local function make_repo(dir)
  vim.fn.mkdir(dir, "p")
  sh({ "git", "init", "-q", "-b", "main" }, dir)
  sh({ "git", "config", "user.email", "t@example.com" }, dir)
  sh({ "git", "config", "user.name", "t" }, dir)
  sh({ "git", "config", "commit.gpgsign", "false" }, dir)
  write(dir .. "/keep.lua", { "local a = 1", "local b = 2", "local c = 3", "return a + b + c" })
  write(dir .. "/gone.txt", { "first", "second", "third" })
  write(dir .. "/old name.txt", { "one", "two" })
  write(dir .. "/dir with space/inner file.md", { "# title", "", "para ```x``` here", "````", "end" })
  sh({ "git", "add", "-A" }, dir)
  sh({ "git", "commit", "-q", "-m", "one" }, dir)
  write(dir .. "/keep.lua", { "local a = 1", "local b = 20", "local c = 3", "local d = 4", "return a + b + c + d" })
  vim.fn.delete(dir .. "/gone.txt")
  sh({ "git", "mv", "old name.txt", "new name.txt" }, dir)
  write(dir .. "/new name.txt", { "one", "two", "three" })
  write(dir .. "/added.txt", { "brand new" })
  write(dir .. "/dir with space/inner file.md", { "# title", "", "para ```x``` here", "````", "end", "more" })
  sh({ "git", "add", "-A" }, dir)
  sh({ "git", "commit", "-q", "-m", "two" }, dir)
  return {
    dir = uv.fs_realpath(dir),
    head = sh({ "git", "rev-parse", "HEAD" }, dir),
    parent = sh({ "git", "rev-parse", "HEAD~1" }, dir),
  }
end

local function settled(view)
  if not (view and view.ready and view.cur_entry and view.cur_layout) then
    return false
  end
  for _, sym in ipairs({ "a", "b" }) do
    local w = view.cur_layout[sym]
    if not (w and w.id and api.nvim_win_is_valid(w.id) and w.file and w.file.bufnr
        and api.nvim_buf_is_valid(w.file.bufnr) and api.nvim_win_get_buf(w.id) == w.file.bufnr) then
      return false
    end
  end
  return true
end

local function wait_for(pred, what)
  assert(vim.wait(10000, pred, 20), "timed out waiting for " .. what)
  vim.wait(60)
end

local function close_views()
  local lib = require("diffview.lib")
  for _, v in ipairs(vim.list_slice(lib.views)) do
    v:close()
    lib.dispose_view(v)
  end
end

local function open_view(repo, args)
  close_views()
  vim.cmd.cd(vim.fn.fnameescape(repo.dir))
  vim.cmd("DiffviewOpen " .. (args or ""))
  local view = require("diffview.lib").get_current_view()
  assert(view, "no view")
  wait_for(function() return settled(view) end, "view to settle")
  return view
end

local function review_win(bufnr)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr then
      api.nvim_set_current_win(win)
      return win
    end
  end
  error("review buffer is not shown in this tab")
end

local function forget_review_buffer(root)
  local bufnr = vim.fn.bufadd(notes.review_path(state_dir, root))
  if api.nvim_buf_is_loaded(bufnr) then
    api.nvim_buf_delete(bufnr, { force = true })
  end
end

local function select_entry(view, pred)
  local target
  for _, e in view.files:iter() do
    if pred(e) then
      target = e
      break
    end
  end
  assert(target, "no entry matched")
  view:set_file(target, false, true)
  wait_for(function() return view.cur_entry == target and settled(view) end, "entry " .. target.path)
  return target
end

local function focus(view, sym)
  api.nvim_set_current_win(view.cur_layout[sym].id)
  return view.cur_layout[sym].file.bufnr
end

local function review_lines(root)
  local path = notes.review_path(state_dir, root)
  local bufnr = vim.fn.bufadd(path)
  if api.nvim_buf_is_loaded(bufnr) then
    return api.nvim_buf_get_lines(bufnr, 0, -1, false), bufnr, path
  end
  return vim.fn.readfile(path), nil, path
end

local function mark_rows(bufnr)
  local rows = {}
  for _, m in ipairs(api.nvim_buf_get_extmarks(bufnr, api.nvim_create_namespace("diff_review_marks"), 0, -1, { details = true })) do
    rows[#rows + 1] = { m[2] + 1, (m[4].end_row or m[2]) + 1 }
  end
  table.sort(rows, function(x, y) return x[1] < y[1] end)
  return rows
end

local function label_texts(bufnr)
  local out = {}
  for _, m in ipairs(api.nvim_buf_get_extmarks(bufnr, api.nvim_create_namespace("diff_review_labels"), 0, -1, { details = true })) do
    out[#out + 1] = { line = m[2] + 1, text = vim.trim(m[4].virt_text[1][1]) }
  end
  table.sort(out, function(x, y) return x.line < y.line end)
  return out
end

local function entries_of(lines)
  local entries, problems = notes.parse(lines)
  return entries, problems
end

local function eq(actual, expected, what)
  if not vim.deep_equal(actual, expected) then
    error(("%s\n  expected: %s\n  actual:   %s"):format(what or "values differ", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function contains(s, sub, what)
  if not s:find(sub, 1, true) then
    error(("%s\n  %q does not contain %q"):format(what or "substring missing", s, sub), 2)
  end
end

local failures, passed = {}, 0
local function test(name, fn)
  messages = {}
  close_views()
  local ok, err = xpcall(fn, debug.traceback)
  if ok then
    passed = passed + 1
    io.stdout:write("ok   " .. name .. "\n")
  else
    failures[#failures + 1] = name .. "\n" .. err
    io.stdout:write("FAIL " .. name .. "\n" .. err .. "\n")
  end
end

if arg[1] == "--reopen" then
  local dir, expected = arg[3], vim.json.decode(arg[4])
  local repo = { dir = uv.fs_realpath(dir) }
  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  dr.refresh()
  local b_rows = mark_rows(view.cur_layout.b.file.bufnr)
  local a_rows = mark_rows(view.cur_layout.a.file.bufnr)
  io.stdout:write(vim.json.encode({ a = a_rows, b = b_rows, entries = #entries_of(review_lines(repo.dir)) }) .. "\n")
  eq(b_rows, expected.b, "right-side marks after restart")
  eq(a_rows, expected.a, "left-side marks after restart")
  io.stdout:write("REOPEN OK\n")
  vim.cmd("qa!")
end

local sample_anchor = {
  id = "0123abcd",
  root = "/tmp/repo with space",
  left = "1111111111111111111111111111111111111111",
  right = "LOCAL",
  side = "b",
  path = "dir/we-->ird `name`.lua",
  lines = { 3, 5 },
  sha256 = string.rep("ab", 32),
  unsaved = true,
  created = "2026-09-04T23:00:00-0400",
}

test("anchor encodes on one line without a comment terminator inside", function()
  local line = notes.encode_anchor(sample_anchor)
  assert(not line:find("\n"), "single line")
  local body = line:match("^<!%-%- diff%-review v1 (.*) %-%->$")
  assert(body, "anchor shape: " .. line)
  assert(not body:find(">", 1, true) and not body:find("<", 1, true), "angle brackets escaped: " .. body)
  contains(line, '{"id":"0123abcd","root":', "field order starts with id, root")
  local decoded = assert(notes.decode_anchor(line))
  eq(decoded, sample_anchor, "round trip")
end)

test("anchor decoding rejects malformed input with a reason", function()
  local function reject(line, needle)
    local a, err = notes.decode_anchor(line)
    assert(a == nil, "should reject: " .. line)
    contains(err, needle, "reason for " .. line)
  end
  reject("<!-- diff-review v2 {} -->", "unsupported anchor version v2")
  reject("<!-- diff-review v1 {not json} -->", "does not parse")
  reject("<!-- diff-review v1 [1,2] -->", "not a JSON object")
  reject('<!-- diff-review v1 {"id":"x"} -->', '"root"')
  local bad = vim.deepcopy(sample_anchor)
  bad.side = "c"
  reject(notes.encode_anchor(bad), '"side"')
  bad = vim.deepcopy(sample_anchor)
  bad.lines = { 5, 3 }
  reject(notes.encode_anchor(bad), '"lines"')
  bad = vim.deepcopy(sample_anchor)
  bad.sha256 = "zz"
  reject(notes.encode_anchor(bad), '"sha256"')
  bad = vim.deepcopy(sample_anchor)
  bad.unsaved = "yes"
  reject(notes.encode_anchor(bad), '"unsaved"')
  reject("<!-- diff-review v1 {\"id\":\"x\"}", "not in the form")
end)

test("parse finds entries, headings, threads, and reports problems", function()
  local a1 = vim.deepcopy(sample_anchor)
  local a2 = vim.deepcopy(sample_anchor)
  a2.id = "deadbeef"
  a2.side = "a"
  local lines = {
    "# Diff review notes",
    "",
    "## `x.lua` lines 3-5 (right: working tree)",
    "",
    notes.encode_anchor(a1),
    "",
    "```lua",
    "code",
    "```",
    "",
    "<!-- TODO: not a thread -->",
    "<!-- PV: first note",
    "> ASTRA: reply",
    "-->",
    "<!-- PV: second comment on the same entry -->",
    "",
    "<!-- diff-review v1 {broken -->",
    "",
    "## `y.lua` line 1 (left: 1111111111)",
    "",
    "some prose between heading and anchor",
    notes.encode_anchor(a2),
    "<!-- SK: thread -->",
    "",
    "<!-- PV: an unrelated note -->",
  }
  local entries, problems = notes.parse(lines)
  eq(#entries, 2, "entry count")
  eq(entries[1].line, 5, "first anchor line")
  eq(entries[1].heading, 3, "first heading")
  eq(entries[1].thread, 12, "first thread skips TODO marker")
  eq(entries[1].anchor.id, "0123abcd", "first id")
  eq(entries[2].line, 22, "second anchor line")
  eq(entries[2].heading, 19, "second heading")
  eq(entries[2].thread, 23, "second thread")
  eq(#problems, 1, "one problem")
  eq(problems[1].line, 17, "problem line")
  contains(problems[1].err, "does not parse", "problem reason")
end)

test("entry text escapes paths and fences", function()
  local lines = notes.entry_lines({
    anchor = sample_anchor,
    excerpt = { "```lua", "x = 1", "````", "" },
    filetype = "markdown",
    tag = "PV",
  })
  eq(lines[1], "## ``dir/we-->ird `name`.lua`` lines 3-5 (right: working tree, unsaved buffer)", "heading")
  eq(lines[2], "", "blank after heading")
  assert(notes.is_anchor_line(lines[3]), "anchor line third")
  eq(lines[5], "`````markdown", "fence longer than any run in the excerpt")
  eq(lines[6], "```lua", "excerpt kept verbatim")
  eq(lines[10], "`````", "closing fence")
  eq(lines[12], "<!-- PV:  -->", "empty thread ready for typing")
  eq(#lines, 12, "line count")
  local entries = notes.parse(lines)
  eq(entries[1].anchor, sample_anchor, "entry parses back")
  eq(entries[1].thread, 12, "thread line")
end)

test("side labels and rev descriptions", function()
  eq(notes.describe_rev("LOCAL"), "working tree")
  eq(notes.describe_rev(":0"), "index")
  eq(notes.describe_rev(":2"), "index stage 2")
  eq(notes.describe_rev("abcdef0123456789abcdef0123456789abcdef01"), "abcdef0123")
  local a = vim.deepcopy(sample_anchor)
  a.side, a.unsaved = "a", nil
  eq(notes.side_label(a), "left: 1111111111")
  eq(notes.code_span("plain"), "`plain`")
  eq(notes.code_span("`tick`"), "`` `tick` ``")
end)

test("status compares comparison, side, path, and fingerprint", function()
  local snap = {
    root = sample_anchor.root, left = sample_anchor.left, right = sample_anchor.right,
    side = "b", path = sample_anchor.path, sha256 = sample_anchor.sha256,
  }
  eq(notes.status(sample_anchor, snap), "current")
  eq(notes.status(sample_anchor, vim.tbl_extend("force", snap, { sha256 = string.rep("00", 32) })), "outdated")
  eq(notes.status(sample_anchor, vim.tbl_extend("force", snap, { side = "a" })), "elsewhere")
  eq(notes.status(sample_anchor, vim.tbl_extend("force", snap, { left = "2222" })), "elsewhere")
  eq(notes.status(sample_anchor, vim.tbl_extend("force", snap, { root = "/other" })), "elsewhere")
  eq(notes.status(sample_anchor, vim.tbl_extend("force", snap, { path = "other.lua" })), "elsewhere")
end)

test("review paths are keyed by worktree and readable", function()
  local p1 = notes.review_path("/state", "/Users/me/code/example")
  local p2 = notes.review_path("/state", "/Users/me/code/example/.local/worktrees/example")
  local p3 = notes.review_path("/state", "/tmp/repo with space/")
  assert(p1 ~= p2, "different worktrees, different files")
  assert(p1:match("^/state/example%-%x+%.md$"), p1)
  assert(p2:match("^/state/example%-%x+%.md$"), p2)
  assert(p3:match("^/state/repo_with_space%-%x+%.md$"), p3)
  local taken = {}
  local id = notes.new_id(taken, "seed")
  taken[id] = true
  assert(notes.new_id(taken, "seed") ~= id, "collision avoided")
  assert(#id == 8, "short id")
end)

local repo = make_repo(sandbox .. "/repo")

local function git_state()
  return {
    status = sh({ "git", "status", "--porcelain" }, repo.dir),
    unstaged = sh({ "git", "diff" }, repo.dir),
    staged = sh({ "git", "diff", "--cached" }, repo.dir),
  }
end

local function assert_clean(what)
  eq(git_state().status, "", what .. ": working tree and index unchanged")
end

local function assert_sources_untouched(view, what)
  for _, sym in ipairs({ "a", "b" }) do
    local bufnr = view.cur_layout[sym].file.bufnr
    if api.nvim_buf_get_name(bufnr) ~= "diffview://null" then
      eq(vim.bo[bufnr].modified, false, what .. ": " .. sym .. " buffer not modified")
    end
  end
end

test("commit-to-commit: notes on both sides, single line and range", function()
  local view = open_view(repo, "HEAD~1..HEAD")
  local entry = select_entry(view, function(e) return e.path == "keep.lua" end)
  local b_buf = focus(view, "b")
  api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  local lines, rbuf, path = review_lines(repo.dir)
  assert(rbuf, "review buffer loaded")
  eq(api.nvim_get_current_buf(), rbuf, "review buffer focused after commenting")
  eq(lines[1], "# Diff review notes: " .. notes.code_span(repo.dir), "header")
  local entries = entries_of(lines)
  eq(#entries, 1, "one entry")
  local a = entries[1].anchor
  eq({ a.side, a.path, a.lines, a.left, a.right, a.root }, { "b", "keep.lua", { 2, 2 }, repo.parent, repo.head, repo.dir }, "anchor")
  eq(a.unsaved, nil, "commit buffer is not an unsaved buffer")
  eq(lines[entries[1].heading], ("## `keep.lua` line 2 (right: %s)"):format(repo.head:sub(1, 10)), "heading")
  eq(lines[entries[1].line + 2], "```lua", "excerpt fence with filetype")
  eq(lines[entries[1].line + 3], "local b = 20", "excerpt content")
  eq(lines[entries[1].thread], "<!-- PV:  -->", "empty thread")
  local cursor = api.nvim_win_get_cursor(0)
  eq(cursor, { entries[1].thread, 9 }, "cursor inside the new note")
  eq(vim.bo[rbuf].modified, true, "review buffer unsaved until :w")
  eq(vim.fn.filereadable(path), 0, "nothing written until :w")
  eq(mark_rows(b_buf), { { 2, 2 } }, "marker on the right side")
  eq(mark_rows(view.cur_layout.a.file.bufnr), {}, "no marker on the left side")

  focus(view, "a")
  vim.cmd("1,2DiffReviewComment")
  vim.cmd("stopinsert")
  lines = review_lines(repo.dir)
  entries = entries_of(lines)
  eq(#entries, 2, "two entries")
  eq({ entries[2].anchor.side, entries[2].anchor.lines }, { "a", { 1, 2 } }, "left range")
  eq(lines[entries[2].heading], ("## `keep.lua` lines 1-2 (left: %s)"):format(repo.parent:sub(1, 10)), "left heading")
  eq({ lines[entries[2].line + 3], lines[entries[2].line + 4] }, { "local a = 1", "local b = 2" }, "left excerpt is the old text")
  assert(entries[1].anchor.id ~= entries[2].anchor.id, "distinct ids")
  eq(mark_rows(view.cur_layout.a.file.bufnr), { { 1, 2 } }, "left marker")
  eq(mark_rows(b_buf), { { 2, 2 } }, "right marker unchanged")
  assert_sources_untouched(view, "after two notes")
  assert_clean("after two notes")
  vim.cmd("silent write")
  eq(vim.fn.filereadable(path), 1, "written by :w")
  eq(entry.path, "keep.lua")
end)

test("deleted, added, renamed, and space-containing paths", function()
  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.status == "D" end)
  focus(view, "b")
  vim.cmd("DiffReviewComment")
  contains(last_message(), "right side shows no file content", "deleted file: right side rejected")
  focus(view, "a")
  vim.cmd("2,3DiffReviewComment")
  vim.cmd("stopinsert")
  local entries = entries_of(review_lines(repo.dir))
  local a = entries[#entries].anchor
  eq({ a.side, a.path, a.lines }, { "a", "gone.txt", { 2, 3 } }, "deleted file annotated on the left")

  select_entry(view, function(e) return e.status == "A" end)
  focus(view, "a")
  vim.cmd("DiffReviewComment")
  contains(last_message(), "left side shows no file content", "added file: left side rejected")
  focus(view, "b")
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  entries = entries_of(review_lines(repo.dir))
  a = entries[#entries].anchor
  eq({ a.side, a.path, a.lines }, { "b", "added.txt", { 1, 1 } }, "added file annotated on the right")

  select_entry(view, function(e) return e.oldpath ~= nil end)
  focus(view, "a")
  api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  focus(view, "b")
  api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  local lines = review_lines(repo.dir)
  entries = entries_of(lines)
  eq(entries[#entries - 1].anchor.path, "old name.txt", "left side of a rename uses the old path")
  eq(entries[#entries].anchor.path, "new name.txt", "right side of a rename uses the new path")
  eq(lines[entries[#entries].heading], ("## `new name.txt` line 3 (right: %s)"):format(repo.head:sub(1, 10)), "heading with spaces")
  eq(lines[entries[#entries].line + 3], "three", "renamed excerpt")

  select_entry(view, function(e) return e.path:find("inner file") ~= nil end)
  focus(view, "b")
  vim.cmd("3,4DiffReviewComment")
  vim.cmd("stopinsert")
  lines = review_lines(repo.dir)
  entries = entries_of(lines)
  a = entries[#entries].anchor
  eq(a.path, "dir with space/inner file.md", "path with spaces")
  eq(lines[entries[#entries].line + 2], "`````markdown", "fence grows past the excerpt's backticks")
  eq({ lines[entries[#entries].line + 3], lines[entries[#entries].line + 4] }, { "para ```x``` here", "````" }, "excerpt")
  eq(mark_rows(view.cur_layout.b.file.bufnr), { { 3, 4 } }, "marker on the new note only")
  assert_sources_untouched(view, "after mixed notes")
  assert_clean("after mixed notes")
  vim.cmd("silent write")
end)

test("markers follow the selected file and survive view and process restarts", function()
  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "gone.txt" end)
  wait_for(function() return #mark_rows(view.cur_layout.a.file.bufnr) == 1 end, "marks on the deleted file")
  eq(mark_rows(view.cur_layout.a.file.bufnr), { { 2, 3 } }, "deleted file note marked on the left")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  wait_for(function() return #mark_rows(view.cur_layout.b.file.bufnr) == 1 end, "marks after reselect")
  eq(mark_rows(view.cur_layout.b.file.bufnr), { { 2, 2 } }, "right marks after reselect")
  eq(mark_rows(view.cur_layout.a.file.bufnr), { { 1, 2 } }, "left marks after reselect")
  vim.cmd("DiffviewClose")
  view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  wait_for(function() return #mark_rows(view.cur_layout.b.file.bufnr) == 1 end, "marks after reopen")
  eq(mark_rows(view.cur_layout.a.file.bufnr), { { 1, 2 } }, "left marks after reopen")
  vim.cmd("DiffviewClose")

  local r = vim.system({
    "nvim", "--clean", "--headless", "-l", script, "--reopen", sandbox, repo.dir,
    vim.json.encode({ a = { { 1, 2 } }, b = { { 2, 2 } } }),
  }, { text = true, env = { DIFFVIEW_PATH = diffview_path, HOME = os.getenv("HOME"), PATH = os.getenv("PATH") } }):wait()
  contains(r.stdout or "", "REOPEN OK", "fresh process sees the notes:\n" .. (r.stdout or "") .. (r.stderr or ""))
end)

test("open jumps to the note under the cursor and labels statuses", function()
  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  focus(view, "a")
  api.nvim_win_set_cursor(0, { 2, 0 })
  vim.cmd("DiffReviewOpen")
  local lines, rbuf = review_lines(repo.dir)
  eq(api.nvim_get_current_buf(), rbuf, "review buffer shown")
  local entries = entries_of(lines)
  eq(api.nvim_win_get_cursor(0)[1], entries[2].thread, "cursor on the left-side note's thread")
  eq(vim.wo.diff, false, "review window is not a diff window")
  eq(vim.wo.scrollbind, false, "review window does not scrollbind")
  eq(#api.nvim_tabpage_list_wins(0), 4, "panel, two diff windows, review split")
  local labels = label_texts(rbuf)
  eq(#labels, #entries, "one label per entry")
  eq(labels[1].text, "current", "right keep.lua note is current")
  eq(labels[2].text, "current", "left keep.lua note is current")
  eq(labels[3].text, "not in the open comparison", "gone.txt note is for another file")
  eq(dr.path(), select(3, review_lines(repo.dir)), "path helper")
  focus(view, "b")
  api.nvim_win_set_cursor(0, { 4, 0 })
  vim.cmd("DiffReviewOpen")
  eq(api.nvim_get_current_buf(), rbuf, "review buffer shown again")
  eq(#api.nvim_tabpage_list_wins(0), 4, "existing split reused")
  vim.cmd("DiffviewClose")
end)

test("outdated notes keep their text and do not mark other code", function()
  local edited = { "local a = 1", "local b = 20", "local c = 3", "local d = 4", "return a + b + c + d", "-- trailing" }
  write(repo.dir .. "/keep.lua", edited)
  local before = git_state()
  local view = open_view(repo, "")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  local b_buf = focus(view, "b")
  api.nvim_win_set_cursor(0, { 5, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  vim.cmd("silent write")
  wait_for(function() return #mark_rows(b_buf) == 1 end, "local mark")
  eq(mark_rows(b_buf), { { 5, 5 } }, "working tree note marked")
  local lines, rbuf = review_lines(repo.dir)
  local entries = entries_of(lines)
  local a = entries[#entries].anchor
  eq({ a.left, a.right, a.side }, { ":0", "LOCAL", "b" }, "index vs working tree anchor")
  eq(lines[entries[#entries].heading], "## `keep.lua` line 5 (right: working tree)", "heading")

  api.nvim_buf_set_lines(b_buf, 0, 0, false, { "-- inserted" })
  wait_for(function() return #mark_rows(b_buf) == 0 end, "marks to clear after edit")
  eq(mark_rows(b_buf), {}, "changed buffer shows no marks")
  eq(entries_of(review_lines(repo.dir))[#entries].anchor.lines, { 5, 5 }, "note text unchanged")
  wait_for(function()
    local l = label_texts(rbuf)
    return l[#l] and l[#l].text:find("outdated") ~= nil
  end, "outdated label")

  api.nvim_set_current_win(view.cur_layout.b.id)
  api.nvim_win_set_cursor(0, { 6, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  lines = review_lines(repo.dir)
  entries = entries_of(lines)
  a = entries[#entries].anchor
  eq(a.unsaved, true, "note taken while the buffer was modified is labeled")
  eq(lines[entries[#entries].heading], "## `keep.lua` line 6 (right: working tree, unsaved buffer)", "heading marks the unsaved buffer")
  eq(lines[entries[#entries].line + 3], "return a + b + c + d", "excerpt is what the buffer showed")
  vim.cmd("silent write")

  api.nvim_buf_set_lines(b_buf, 0, 1, false, {})
  wait_for(function() return #mark_rows(b_buf) == 1 end, "marks to return after reverting the edit")
  eq(mark_rows(b_buf), { { 5, 5 } }, "only the note matching the buffer content is marked")
  eq(api.nvim_buf_get_lines(b_buf, 0, -1, false), edited, "source buffer back to the file content")
  vim.bo[b_buf].modified = false
  eq(git_state(), before, "index and working tree unchanged by notes")
  vim.cmd("DiffviewClose")

  sh({ "git", "add", "keep.lua" }, repo.dir)
  sh({ "git", "commit", "-q", "-m", "three" }, repo.dir)
  view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  dr.refresh()
  eq(mark_rows(view.cur_layout.b.file.bufnr), {}, "another revision shows no marks")
  eq(mark_rows(view.cur_layout.a.file.bufnr), {}, "another revision shows no marks on the left")
  focus(view, "b")
  api.nvim_win_set_cursor(0, { 5, 0 })
  vim.cmd("DiffReviewOpen")
  local labels = label_texts(rbuf)
  eq(#labels, #entries, "labels for every note")
  for _, l in ipairs(labels) do
    eq(l.text, "not in the open comparison", "every note is elsewhere in the new comparison")
  end
  vim.cmd("DiffviewClose")
  sh({ "git", "reset", "-q", "--hard", "HEAD~1" }, repo.dir)
  assert_clean("repo reset")
end)

test("external replies survive refresh and unsaved buffers are protected", function()
  forget_review_buffer(repo.dir)
  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  vim.cmd("DiffReviewOpen")
  local lines, rbuf, path = review_lines(repo.dir)
  assert(rbuf, "review buffer loaded by :DiffReviewOpen")
  eq(vim.bo[rbuf].modified, false, "review buffer starts clean")
  local entries = entries_of(lines)
  local thread = entries[1].thread
  local disk = vim.fn.readfile(path)
  disk[thread] = "<!-- PV: Why did b change?"
  table.insert(disk, thread + 1, "> ASTRA: The constant moved to the config file.")
  table.insert(disk, thread + 2, ">> PV: Then say so in the commit message.")
  table.insert(disk, thread + 3, "-->")
  write(path, disk)
  focus(view, "b")
  api.nvim_win_set_cursor(0, { 3, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  lines = review_lines(repo.dir)
  eq({ lines[thread], lines[thread + 1], lines[thread + 2], lines[thread + 3] }, {
    "<!-- PV: Why did b change?",
    "> ASTRA: The constant moved to the config file.",
    ">> PV: Then say so in the commit message.",
    "-->",
  }, "external thread visible after appending")
  entries = entries_of(lines)
  eq(entries[#entries].anchor.lines, { 3, 3 }, "new note appended after the external edit")
  vim.cmd("silent write")

  api.nvim_buf_set_lines(rbuf, thread + 2, thread + 2, false, { ">>> ASTRA: Done." })
  eq(vim.bo[rbuf].modified, true, "buffer has an unsaved reply")
  disk = vim.fn.readfile(path)
  disk[#disk + 1] = ""
  disk[#disk + 1] = "<!-- SK: external note while the buffer is dirty -->"
  write(path, disk)
  local before = api.nvim_buf_get_lines(rbuf, 0, -1, false)
  api.nvim_win_set_cursor(view.cur_layout.b.id, { 1, 0 })
  api.nvim_set_current_win(view.cur_layout.b.id)
  vim.cmd("DiffReviewComment")
  contains(last_message(), "changed on disk while its buffer has unsaved edits", "append refused")
  eq(api.nvim_buf_get_lines(rbuf, 0, -1, false), before, "buffer untouched by the refusal")
  eq(vim.fn.readfile(path), disk, "disk untouched by the refusal")
  review_win(rbuf)
  vim.cmd("edit!")
  eq(vim.bo[rbuf].modified, false, "reloaded")
  eq(api.nvim_buf_get_lines(rbuf, 0, -1, false), disk, "reload shows the external note")
  api.nvim_set_current_win(view.cur_layout.b.id)
  api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  lines = review_lines(repo.dir)
  eq(lines[#disk], "<!-- SK: external note while the buffer is dirty -->", "external note kept")
  eq(entries_of(lines)[#entries + 1].anchor.lines, { 1, 1 }, "append works again after the reload")
  vim.cmd("silent write")
  vim.cmd("DiffviewClose")
end)

test("two worktrees of one repo keep separate notes", function()
  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  dr.refresh()
  local own = mark_rows(view.cur_layout.b.file.bufnr)
  assert(#own > 0, "first worktree has marks to compare against")
  local wt = sandbox .. "/wt2"
  sh({ "git", "worktree", "add", "-q", "--detach", wt, "HEAD" }, repo.dir)
  local other = { dir = uv.fs_realpath(wt) }
  view = open_view(other, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  dr.refresh()
  eq(mark_rows(view.cur_layout.b.file.bufnr), {}, "no marks from the first worktree")
  eq(mark_rows(view.cur_layout.a.file.bufnr), {}, "no marks from the first worktree on the left")
  vim.cmd("DiffReviewOpen")
  contains(last_message(), "no review notes yet", "other worktree has no notes")
  focus(view, "b")
  vim.cmd("DiffReviewComment")
  vim.cmd("stopinsert")
  local _, _, path2 = review_lines(other.dir)
  local _, _, path1 = review_lines(repo.dir)
  assert(path1 ~= path2, "separate files: " .. path1 .. " vs " .. path2)
  vim.cmd("silent write")
  vim.cmd("DiffviewClose")
  view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  dr.refresh()
  eq(mark_rows(view.cur_layout.b.file.bufnr), own, "first worktree still shows only its own notes")
  vim.cmd("DiffviewClose")
end)

test("unsupported places and malformed anchors are rejected safely", function()
  vim.cmd("tabnew")
  vim.cmd("DiffReviewComment")
  contains(last_message(), "no Diffview in this tab", "outside diffview")
  vim.cmd("tabclose")

  local view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  api.nvim_set_current_win(view.panel.winid)
  vim.cmd("DiffReviewComment")
  contains(last_message(), "move the cursor into one of the two diff windows", "file panel")
  vim.cmd("DiffviewClose")

  vim.cmd("DiffviewFileHistory keep.lua")
  local hv = require("diffview.lib").get_current_view()
  wait_for(function() return hv.ready end, "history view")
  vim.wait(500)
  vim.cmd("DiffReviewComment")
  contains(last_message(), "FileHistoryView is not supported", "history view rejected")
  vim.cmd("DiffviewClose")

  view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  dr.refresh()
  local own = mark_rows(view.cur_layout.b.file.bufnr)
  assert(#own > 0, "marks to compare against")
  vim.cmd("DiffviewClose")
  local _, _, path = review_lines(repo.dir)
  forget_review_buffer(repo.dir)
  local disk = vim.fn.readfile(path)
  disk[#disk + 1] = ""
  disk[#disk + 1] = "<!-- diff-review v1 {\"id\": 5} -->"
  disk[#disk + 1] = "<!-- diff-review v9 {} -->"
  write(path, disk)
  view = open_view(repo, "HEAD~1..HEAD")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  vim.cmd("DiffReviewOpen")
  local lines, rbuf = review_lines(repo.dir)
  eq(lines, disk, "buffer reloaded from disk")
  local _, problems = entries_of(lines)
  eq(#problems, 2, "both malformed anchors reported")
  local labels = label_texts(rbuf)
  contains(labels[#labels - 1].text, "malformed anchor", "label for malformed anchor")
  contains(labels[#labels].text, "unsupported anchor version", "label for version")
  eq(mark_rows(view.cur_layout.b.file.bufnr), own, "valid notes still marked")
  vim.cmd("DiffviewClose")
end)

test("open works outside a Diffview through the Git root of the current file", function()
  vim.cmd("tabnew")
  vim.cmd.cd(vim.fn.fnameescape(repo.dir))
  vim.cmd("edit keep.lua")
  local _, _, path = review_lines(repo.dir)
  eq(dr.path(), path, "path resolves from the current file's worktree")
  vim.cmd("DiffReviewOpen")
  eq(api.nvim_buf_get_name(0), path, "review file opened in a split")
  eq(#api.nvim_tabpage_list_wins(0), 2, "one split below the file")
  eq(label_texts(api.nvim_get_current_buf()), {}, "no status labels without a comparison")
  vim.cmd("tabclose")

  vim.cmd("tabnew")
  local outside = vim.fn.tempname()
  vim.fn.mkdir(outside, "p")
  vim.cmd.cd(vim.fn.fnameescape(outside))
  vim.cmd("DiffReviewOpen")
  contains(last_message(), "not inside a Git worktree", "no repo, no notes")
  vim.cmd("tabclose")
end)

test("mappings live only on diff buffers inside the view", function()
  write(repo.dir .. "/keep.lua", { "local a = 1", "local b = 20", "local c = 3", "local d = 4", "return a + b + c + d", "-- again" })
  local view = open_view(repo, "")
  select_entry(view, function(e) return e.path == "keep.lua" end)
  local b_buf = view.cur_layout.b.file.bufnr
  local function maps(bufnr, mode)
    local out = {}
    for _, m in ipairs(api.nvim_buf_get_keymap(bufnr, mode)) do
      if m.lhs:match("^ n") then
        out[m.lhs] = m.rhs
      end
    end
    return out
  end
  eq(maps(b_buf, "n"), { [" nc"] = "<Cmd>DiffReviewComment<CR>", [" no"] = "<Cmd>DiffReviewOpen<CR>" }, "normal maps on the local buffer")
  eq(maps(b_buf, "x"), { [" nc"] = ":DiffReviewComment<CR>" }, "visual map on the local buffer")
  eq(maps(view.cur_layout.a.file.bufnr, "n")[" nc"], "<Cmd>DiffReviewComment<CR>", "map on the index buffer")
  for _, m in ipairs(api.nvim_buf_get_keymap(b_buf, "n")) do
    if m.lhs:match("^ [cr]") then
      assert(not tostring(m.rhs or ""):find("DiffReview"), "this module must not map under leader-c or leader-r: " .. m.lhs)
    end
  end
  vim.cmd("DiffviewClose")
  eq(api.nvim_buf_is_loaded(b_buf), true, "local buffer stays loaded")
  eq(maps(b_buf, "n"), {}, "maps removed from the local buffer after closing")
  eq(mark_rows(b_buf), {}, "marks removed after closing")
  sh({ "git", "checkout", "--", "keep.lua" }, repo.dir)
end)

io.stdout:write(("\n%d passed, %d failed\n"):format(passed, #failures))
if #failures > 0 then
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
